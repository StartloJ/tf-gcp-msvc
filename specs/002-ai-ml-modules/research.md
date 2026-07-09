# Research: AI/ML Platform Shared Modules

**Feature**: `002-ai-ml-modules` | **Date**: 2026-07-08

## Decision 1 — Private Service Connect (PSC) Architecture

**Decision**: Use **one generic `modules/networks/psc` module** that handles both GCP API bundle endpoints and service-specific endpoints via a `psc_type` variable. Service modules output `service_attachment_uri` when PSC is applicable.

**Rationale**: PSC in GCP has two distinct patterns:

### Pattern A — Google APIs Bundle (one endpoint per VPC)
All Google-managed control-plane services (Secret Manager, KMS, DLP, Cloud Storage, BigQuery, Cloud Logging, Dataplex, Artifact Registry) are accessed via a single PSC endpoint targeting the `all-apis` bundle. This is provisioned **once per VPC**, not per service.

Terraform resources (consumer side):
```
google_compute_global_address           — reserves internal IP for the PSC endpoint
google_compute_global_forwarding_rule   — PSC rule targeting "all-apis" bundle
google_dns_managed_zone                 — private zone for *.googleapis.com
google_dns_record_set                   — A record pointing to the PSC internal IP
```

### Pattern B — Service-Specific PSC (Cloud SQL, Cloud Run, custom services)
Services that publish a `google_compute_service_attachment` get their own PSC forwarding rule per consumer VPC.

Terraform resources (consumer side):
```
google_compute_address                  — regional internal IP
google_compute_forwarding_rule          — points to service_attachment_uri
```

### Module Design
- `modules/networks/psc` accepts `psc_type = "google-apis"` or `"service-attachment"`.
- For `google-apis`: creates global address + global forwarding rule + DNS records for `*.googleapis.com` and `*.googleapis.com.` — one call covers all Google-managed APIs.
- For `service-attachment`: accepts `service_attachment_uri` (output from Cloud SQL / Cloud Run module) and creates regional address + regional forwarding rule.
- Each service module that supports PSC producer mode outputs `service_attachment_uri` for wiring into the PSC module.

**Alternatives Considered**:
- Per-service PSC sub-modules: rejected — Pattern A is inherently shared across all googleapis.com APIs; embedding it per-service would create duplicate infrastructure.
- Central PSC "manager" service: not a GCP concept; there is no GCP-native service that centrally manages all PSC endpoints. The PSC module IS the manager.

---

## Decision 2 — Enterprise Network Egress Control

**Decision**: Use **`modules/networks/secure-web-proxy`** (GCP Secure Web Proxy) as the enterprise egress control module. The existing `modules/networks/router-nat` handles non-HTTP egress (OS updates, raw TCP/UDP to fixed destinations).

**Rationale**:

| Egress concern | Tool | Why chosen |
|---|---|---|
| HTTP/HTTPS to internet + external APIs | Secure Web Proxy (SWP) | URL-based allowlist/denylist, TLS inspection, per-workload identity enforcement |
| Non-HTTP egress (apt, raw TCP) | Cloud NAT (existing module) | IP/port masquerade for fixed non-proxy traffic |
| GCP API access control | VPC Service Controls | Data exfiltration prevention at GCP control plane (separate feature) |

**How Secure Web Proxy works**:
SWP is a GCP-managed explicit forward proxy deployed inside the VPC. Workloads set `HTTP_PROXY` / `HTTPS_PROXY` to the SWP internal IP. All HTTP/HTTPS traffic flows through the proxy, where URL-based security policy rules (allow/deny by FQDN regex or URL list) are enforced before traffic reaches the internet.

SWP routes `*.googleapis.com` requests to `restricted.googleapis.com`, which integrates with VPC Service Controls perimeters for API-level data exfiltration prevention.

**Terraform resources for `modules/networks/secure-web-proxy`**:
```
google_network_security_gateway_security_policy         — top-level policy (allow/deny)
google_network_security_gateway_security_policy_rule    — per-rule (URL pattern, action)
google_network_services_gateway                         — the SWP gateway resource
google_compute_subnetwork                               — proxy-only subnet (INTERNAL_HTTPS_LOAD_BALANCER purpose)
```
Optional (for TLS inspection):
```
google_certificate_manager_certificate_map              — CA certificate for TLS interception
```

**Recommended egress architecture for AI/ML workloads**:
1. SWP gateway in a dedicated proxy-only subnet → workloads set `HTTP_PROXY` env var to SWP IP.
2. Egress firewall rule: deny all internet-bound traffic EXCEPT to SWP IP and the PSC endpoint (Pattern A above).
3. Cloud NAT with manual IP allocation for fixed-IP non-proxied egress (OS patch, pull images from Artifact Registry).
4. VPC Service Controls perimeter around AI/ML project (separate feature, not in this spec).

**Alternatives Considered**:
- Hierarchical Firewall Policies alone: rejected — IP/port-based only; cannot inspect HTTP content, URLs, or enforce workload identity policies.
- Cloud Armor: rejected — ingress DDoS/WAF only, not an egress proxy.
- Third-party NVA (Palo Alto, Fortinet via Marketplace): rejected — higher operational overhead; SWP is GCP-native, fully managed, and lower cost.
- Simple Cloud NAT for all egress: rejected — no content inspection, not enterprise-appropriate for AI/ML workloads calling external model APIs.

---

## Decision 3 — DR Strategy (GCS + Dataproc)

**Decision**: DR is implemented as optional parameters on the primary service modules, not as separate DR-specific modules.

**Rationale**:
- **GCS DR**: `variable "dr_replication_region"` on `modules/storage/gcs`. When set, the module creates a `google_storage_bucket_replication_policy` to replicate to the specified region. No new module needed.
- **Dataproc DR**: `variable "standby"` (`bool`) on `modules/data/dataproc`. When `true`, the module provisions a secondary cluster in `var.dr_region` with the same machine type and image version as the primary.

**Alternatives Considered**:
- Separate `modules/storage/gcs-dr` and `modules/data/dataproc-dr`: rejected — duplicates all variables; a flag inside the primary module is simpler and avoids drift between primary and DR configurations.

---

## Decision 4 — New Module Category Taxonomy

**Decision**: Extend the existing 3-category taxonomy with 6 new categories:

| Category | Path | Modules |
|---|---|---|
| Networks (extended) | `modules/networks/` | psc, load-balancer, secure-web-proxy |
| Workload (extended) | `modules/workload/` | cloud-run |
| Security (new) | `modules/security/` | secret-manager, kms, dlp |
| Governance (new) | `modules/governance/` | dataplex |
| Data (new) | `modules/data/` | dataproc, bigquery |
| Storage (new) | `modules/storage/` | gcs |
| API (new) | `modules/api/` | api-gateway, cloud-endpoints |
| Observability (new) | `modules/observability/` | cloud-logging |

**Rationale**: Follows constitution Principle I ("additional categories added here when new resource families are introduced"). Each category represents a distinct resource family with different provider schema, lifecycle characteristics, and IAM patterns.

---

## Decision 5 — Artifact Registry for AI/ML

**Decision**: Existing `modules/workload/artifact-registry` is reused for model storage without modification.

**Rationale**: The module already accepts `format = "DOCKER"` (and `"MAVEN"`, `"NPM"`). ML model storage in Artifact Registry uses the same `DOCKER` format — Vertex AI Model Registry also pulls from AR Docker repositories. No new module is needed; the AI/ML stack calls the existing module with `format = "DOCKER"`.

---

## Decision 6 — Load Balancer Module Scope

**Decision**: `modules/networks/load-balancer` covers **HTTP(S) Global External Application Load Balancer** and **Regional Internal Application Load Balancer** only. TCP/SSL proxy, Network LB, and Gateway LB are out of scope for v1.

**Rationale**: AI/ML model serving (Cloud Run backends, Vertex AI endpoints) primarily needs HTTP(S) LB. Selectable via `load_balancer_type = "external-global" | "internal-regional"`.

Terraform resources:
```
google_compute_backend_service           — backend pointing to NEG or instance group
google_compute_url_map                   — routing rules
google_compute_target_https_proxy        — TLS termination
google_compute_global_forwarding_rule    — external; or google_compute_forwarding_rule for internal
google_compute_managed_ssl_certificate   — for external HTTPS
```

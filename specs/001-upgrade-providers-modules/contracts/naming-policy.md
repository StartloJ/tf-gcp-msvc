# Contract: GCP Resource Naming Policy

**Feature**: 001-upgrade-providers-modules (US5)
**Date**: 2026-07-08
**Source**: Notion TF-development page (retrieved 2026-07-08)
**Authority**: Supersedes the naming table in constitution v1.0.0 (which will be
updated in a follow-up constitution amendment).

---

## Governing Rules

1. All tokens are Terraform **variables** — no hardcoded org/domain/env strings in HCL.
2. Token separators are **hyphens** (`-`) except for BigQuery datasets which use
   **underscores** (`_`).
3. `nn` sequence counters are **zero-padded two-digit** integers (`01`, `02`, ...).
4. `a/b` suffix on VPN tunnels and BGP peers denotes the redundant tunnel pair.
5. Names MUST be lowercase; no spaces or special characters except hyphens and underscores.

---

## Pattern Table

| Resource | Pattern | Example |
|---|---|---|
| Folder | `fld-<org>-<domain/env>` | `fld-obk-platform` |
| Project | `prj-<org>-<domain>-<purpose>[-<env>]` | `prj-obk-data-proc-prd` |
| Shared VPC attachment | `svpcatt-<host>-to-<service>` | `svpcatt-plt-net-host-to-data-proc-prd` |
| VPC | `vpc-<org>-<purpose>-<env>` | `vpc-obk-lz-shd` |
| Subnet | `snet-<org>-<domain>-<env>-<region>` | `snet-obk-data-prd-th` |
| PGA config | `pga-<org>-<domain>-<env>-<region>` | `pga-obk-data-prd-th` |
| VPC Flow Logs config | `vfl-<org>-<domain>-<env>-<region>` | `vfl-obk-data-prd-th` |
| Cloud NAT | `nat-<org>-<domain>-<purpose>-<env>-<region>-nn` | `nat-obk-con-egress-shd-th-01` |
| Cloud Router | `cr-<org>-<domain>-<purpose>-<env>-<region>-nn` | `cr-obk-con-vpn-shd-th-01` |
| HA VPN Gateway | `havgw-<org>-<peer>-<env>-<region>-nn` | `havgw-obk-onprem-shd-th-01` |
| VPN Tunnel | `vpntun-<org>-<peer>-<env>-<region>-a/b` | `vpntun-obk-onprem-shd-th-a` |
| BGP Peer | `bgp-<org>-<peer>-<env>-<region>-a/b` | `bgp-obk-onprem-shd-th-a` |
| PSC Google APIs | `psc-<org>-googleapis-<bundle>-<env>-<region>-nn` | `psc-obk-googleapis-vpcsc-shd-th-01` |
| Firewall rule | `fwr-<action>-<src>-to-<dst>-<service>` | `fwr-allow-data-prd-to-ml-prd-443` |
| DNS zone | `dnsz-<org>-<scope>-<env>` | `dnsz-obk-internal-shd` |
| Secret | `secret-<org>-<workload>-<env>-<purpose>` | `secret-obk-con-shd-vpn-psk` |
| KMS key ring | `kr-<org>-<domain>-<env>-<region>` | `kr-obk-data-prd-th` |
| KMS key | `key-<service>-<purpose>-<env>-<region>` | `key-bq-cmek-prd-th` |
| DLP template | `dlpt-<org>-<domain>-<env>-<purpose>-<region>` | `dlpt-obk-data-prd-pii-th` |
| VPC-SC perimeter | `sp-<org>-<scope>-<env>` | `sp-obk-data-ml-prd` |
| Log bucket | `logb-<org>-<scope>-<env>-<region>` | `logb-obk-data-prd-th` |
| Log sink | `logsink-<org>-<source>-to-<dest>` | `logsink-obk-prd-to-central` |
| Notification channel | `mnc-<org>-<team>-<method>-<env>` | `mnc-obk-secops-email-prd` |
| Alert policy | `ap-<org>-<service>-<condition>-<env>-<region>` | `ap-obk-vpn-tunnel-down-shd-th` |
| Storage bucket | `bkt-<org>-<domain>-<purpose>-<env>-<region>-uniq` | `bkt-obk-data-landing-prd-th-a1b2` |
| BigQuery dataset | `ds_<domain>_<purpose>_<env>_<region>` | `ds_data_landing_prd_th` |
| Dataproc cluster | `dpc-<org>-<domain>-<purpose>-<env>-<region>-nn` | `dpc-obk-data-etl-prd-th-01` |
| Cloud SQL instance | `sql-<org>-<domain>-<engine>-<env>-<region>` | `sql-obk-platform-pg-example-sg` |
| Artifact Registry | `ar-<org>-<domain>-<artifact>-<env>-<region>` | `ar-obk-ml-model-prd-sg` |
| Vertex AI endpoint | `vtxep-<org>-<workload>-<env>-<region>-nn` | `vtxep-obk-footfall-prd-sg-01` |

---

## Token Reference

| Token | Variable | Canonical values / notes |
|---|---|---|
| `<org>` | `var.org` | Organisation abbreviation; free-form string |
| `<domain>` | `var.domain` | Business domain: `platform`, `security`, `connectivity`, `data`, `ml`, `sandbox` |
| `<env>` | `var.env` | `shd` (shared), `prd` (prod), `np` (non-prod), `sbx` (sandbox) |
| `<region>` | `var.region_code` | Short region code: `th` = asia-southeast2, `sg` = asia-southeast1 |
| `<purpose>` | caller-supplied local | Workload descriptor: `main`, `lz`, `egress`, `vpn` |
| `<peer>` | caller-supplied local | VPN peer identifier: `onprem`, `partner` |
| `<scope>` | caller-supplied local | Perimeter/log scope: `internal`, `external` |
| `<artifact>` | `var.artifact_type` | Registry artifact type: `docker`, `maven`, `npm` — declare as stack variable |
| `<engine>` | `var.db_engine` | Database engine short code: `pg` (PostgreSQL), `mysql` — declare as stack variable |
| `<workload>` | caller-supplied local | App/workload name |
| `<bundle>` | caller-supplied local | PSC API bundle: `vpcsc`, `all` |
| `nn` | sequence counter local | Zero-padded integer starting at `01` |
| `a/b` | constant suffix | Tunnel redundancy: `a` = primary, `b` = secondary |

---

## `common_labels` Contract

Every stack MUST define this local. Every module MUST accept `labels = map(string)` and
merge it into every resource.

```hcl
locals {
  common_labels = {
    org          = var.org
    landing_zone = "gcp_lz"
    env          = var.env
    domain       = var.domain
    app          = var.app
    component    = var.component
    owner_team   = var.owner_team
    cost_center  = var.cost_center
    managed_by   = "terraform"
    data_class   = var.data_class
  }
}
```

**Validated enumerations** (enforced by `validation {}` blocks in stack `variables.tf`):

| Variable | Allowed values |
|---|---|
| `env` | `shd`, `prd`, `np`, `sbx` |
| `data_class` | `public`, `internal`, `confidential`, `restricted`, `na` |

---

## Acceptance Test

```bash
# No resource name uses the old pattern (<env>-<component>-<type>)
grep -rn 'name.*=.*"example-' stacks/ --include="*.tf"  # should return nothing

# Every stack locals block contains managed_by = "terraform"
grep -rn 'managed_by' stacks/ --include="*.tf"  # should return one match per stack

# Every module declares a labels variable
for d in modules/networks/* modules/sql/* modules/workload/*; do
  grep -q 'variable "labels"' "$d/variables.tf" || echo "MISSING labels var: $d"
done
```

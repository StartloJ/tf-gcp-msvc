# Naming Conventions: AI/ML Platform Modules

**Feature**: `002-ai-ml-modules` | **Date**: 2026-07-08
**Authority**: Extends `specs/001-upgrade-providers-modules/contracts/naming-policy.md`

## New Resource Name Patterns

All names constructed in module `locals {}` from naming-token variables. No hardcoded strings.

| Resource | Pattern | Terraform local name | Example |
|---|---|---|---|
| Dataproc cluster | `dpc-<org>-<domain>-<purpose>-<env>-<region>-01` | `dataproc_name` | `dpc-obk-ml-etl-np-sg-01` |
| BigQuery dataset | `ds_<domain>_<purpose>_<env>_<region>` (underscores) | `bq_dataset_id` | `ds_ml_features_np_sg` |
| GCS bucket | `bkt-<org>-<domain>-<purpose>-<env>-<region>-<uniq>` | `gcs_bucket_name` | `bkt-obk-ml-models-np-sg-a1b2` |
| Cloud Run service | `cr-<org>-<domain>-<purpose>-<env>` | `cloud_run_name` | `cr-obk-ml-inference-np` |
| KMS key ring | `kr-<org>-<domain>-<env>-<region>` | `kms_key_ring_name` | `kr-obk-ml-np-sg` |
| Dataplex lake | `lake-<org>-<domain>-<purpose>-<env>` | `dataplex_lake_name` | `lake-obk-ml-raw-np` |
| Log sink | `logsink-<org>-<domain>-<purpose>-<env>` | `log_sink_name` | `logsink-obk-ml-audit-np` |
| PSC endpoint | `psc-<org>-<domain>-<type>-<env>-<region>-01` | `psc_name` | `psc-obk-ml-googleapis-np-sg-01` |
| SWP gateway | `swp-<org>-<domain>-<env>-<region>` | `swp_name` | `swp-obk-ml-np-sg` |
| HTTP LB | `lb-<org>-<domain>-<purpose>-<env>` | `lb_name` | `lb-obk-ml-inference-np` |
| API Gateway | `apigw-<org>-<domain>-<purpose>-<env>` | `api_gateway_name` | `apigw-obk-ml-model-np` |
| DLP template | `dlpt-<org>-<domain>-<env>-<purpose>-<region>` | `dlp_template_name` | `dlpt-obk-ml-np-pii-sg` |

## Token Reference

All tokens come from standard stack variables (same as in `001-upgrade-providers-modules`):

| Token | Variable | Example values |
|---|---|---|
| `<org>` | `var.org` | `obk` |
| `<domain>` | `var.domain` | `ml`, `data`, `platform` |
| `<env>` | `var.env` | `shd`, `prd`, `np`, `sbx` |
| `<region>` | `var.region_code` | `sg` (asia-southeast1) |
| `<purpose>` | module-specific suffix variable | `etl`, `inference`, `models`, `audit` |
| `<uniq>` | `var.unique_suffix` | `a1b2` (short random suffix for globally unique names) |

## BigQuery Dataset Naming Note

BigQuery dataset IDs use underscores (`_`) throughout — not hyphens. The pattern `ds_<domain>_<purpose>_<env>_<region>` matches the existing naming policy. Construct as:

```hcl
locals {
  bq_dataset_id = "ds_${var.domain}_${var.dataset_id_suffix}_${var.env}_${var.region_code}"
}
```

## GCS Bucket Global Uniqueness

GCS bucket names are globally unique across all GCP projects. The `<uniq>` suffix (4–6 alphanumeric characters from `var.unique_suffix`) ensures uniqueness. Callers supply this value; the module does not auto-generate it (to keep naming deterministic across plan/apply cycles).

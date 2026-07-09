output "lake_id" {
  description = "The fully-qualified resource ID of the Dataplex lake."
  value       = google_dataplex_lake.this.id
}

output "zone_ids" {
  description = "Map of zone name to fully-qualified Dataplex zone resource ID."
  value       = { for k, z in google_dataplex_zone.zones : k => z.id }
}

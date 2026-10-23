output "id" {
  description = "Map of secrets key to secret id (<name>-<key>). Null when create is false."
  value       = var.create ? { for k, s in google_secret_manager_secret.this : k => s.secret_id } : null
}

output "name" {
  description = "Prefix used for secret ids (var.name). Null when create is false."
  value       = var.create ? var.name : null
}

output "self_link" {
  description = "Map of secrets key to full resource name (projects/<project>/secrets/<id>). Null when create is false."
  value       = var.create ? { for k, s in google_secret_manager_secret.this : k => s.name } : null
}

output "secret_ids" {
  description = "Map of secrets key to secret id (<name>-<key>). Null when create is false."
  value       = var.create ? { for k, s in google_secret_manager_secret.this : k => s.secret_id } : null
}

output "version_names" {
  description = "Map of secrets key to secret version resource name, only for keys that were given a value. Null when create is false."
  value       = var.create ? { for k, v in google_secret_manager_secret_version.this : k => v.name } : null
  sensitive   = true
}

output "labels" {
  description = "Labels applied to every secret, with context.extra_tags merged in. Null when create is false."
  value       = var.create ? local.labels : null
}

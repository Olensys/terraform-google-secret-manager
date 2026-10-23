locals {
  extra_labels = { for k, v in var.context.extra_tags :
  substr(replace(lower(k), "/[^a-z0-9_-]/", "-"), 0, 63) => substr(replace(lower(v), "/[^a-z0-9_-]/", "-"), 0, 63) }
  labels = merge(local.extra_labels, var.labels)

  # Keys and replication/accessor layout are not secret; only values are.
  secret_keys = var.create ? toset(nonsensitive(keys(var.secrets))) : toset([])

  version_keys = toset([for k in local.secret_keys : k if nonsensitive(var.secrets[k].create_version)])

  accessor_pairs = {
    for p in flatten([
      for k in local.secret_keys : [
        for m in toset(nonsensitive(var.secrets[k].accessor_members)) : { key = k, member = m }
      ]
    ]) : "${p.key}/${p.member}" => p
  }
}

resource "google_secret_manager_secret" "this" {
  for_each = local.secret_keys

  project   = var.project_id
  secret_id = "${var.name}-${each.key}"
  labels    = local.labels

  replication {
    dynamic "auto" {
      for_each = length(coalesce(nonsensitive(var.secrets[each.key].replication_locations), [])) == 0 ? [1] : []
      content {
        dynamic "customer_managed_encryption" {
          for_each = var.kms_key_name != null ? [1] : []
          content {
            kms_key_name = var.kms_key_name
          }
        }
      }
    }

    dynamic "user_managed" {
      for_each = length(coalesce(nonsensitive(var.secrets[each.key].replication_locations), [])) > 0 ? [1] : []
      content {
        dynamic "replicas" {
          for_each = toset(nonsensitive(var.secrets[each.key].replication_locations))
          content {
            location = replicas.value
            dynamic "customer_managed_encryption" {
              for_each = var.kms_key_name != null ? [1] : []
              content {
                kms_key_name = var.kms_key_name
              }
            }
          }
        }
      }
    }
  }
}

resource "google_secret_manager_secret_version" "this" {
  for_each = local.version_keys

  secret      = google_secret_manager_secret.this[each.key].id
  secret_data = var.secrets[each.key].value
}

resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each = local.accessor_pairs

  project   = var.project_id
  secret_id = google_secret_manager_secret.this[each.value.key].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value.member
}

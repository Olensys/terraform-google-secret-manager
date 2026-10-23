# terraform-google-secret-manager

Secret Manager secrets from a map with optional initial versions, CMEK and accessor IAM

## Opinions

- Secret ids are `<name>-<key>`; `name` is at most 40 characters and each key at most 20 (letters, digits, `_`, `-`).
- A secret version is created only when `create_version` (default true, plan-known) is set and a `value` is given; `create_version = true` with no value is rejected. Secrets with `create_version = false` are created empty, to be populated out of band. Removing the value or setting `create_version = false` destroys the module-managed version.
- `id` is the contract alias of `secret_ids` (both map key to secret id).
- An empty `replication_locations` list means automatic replication.
- Replication is automatic unless `replication_locations` is set, which switches that secret to user-managed replicas.
- `accessor_members` get `roles/secretmanager.secretAccessor` on that secret only, never project-wide.
- Secret values are stored in Terraform state (plain `secret_data`, for the Terraform 1.5 floor). Protect the state backend, or leave `value` null and add versions out of band.
- `kms_key_name` enables customer-managed encryption on every secret; with user-managed replication the key must be usable in every replica location.
- `secrets` is sensitive; only its keys, locations and members are un-sensitised to drive `for_each`. `version_names` is sensitive.
- `context.extra_tags` keys and values are normalised to valid GCP label syntax (lowercase, `[^a-z0-9_-]` → `-`, 63 chars); `labels` are applied verbatim and win.

## Usage

```hcl
module "naming" {
  source  = "git::https://github.com/Olensys/terraform-null-naming.git?ref=v1.0.1"
  context = var.context
}

module "this" {
  source = "git::https://github.com/Olensys/terraform-google-secret-manager.git?ref=v1.1.0"

  name       = module.naming.name
  project_id = "my-project"
  context = var.context

  secrets = {
    db_password = { value = var.db_password, accessor_members = ["serviceAccount:api@my-project.iam.gserviceaccount.com"] }
    api_key     = { create_version = false }
  }
  labels  = module.naming.labels
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0, < 8.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0, < 8.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_secret_manager_secret.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_iam_member.accessor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_version.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_context"></a> [context](#input\_context) | Deployment context used for naming, tagging and environment-dependent defaults. | <pre>object({<br/>    organization = string<br/>    environment  = string<br/>    application  = string<br/>    component    = optional(string)<br/>    owner        = string<br/>    cost_center  = string<br/>    extra_tags   = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Prefix for secret ids; each secret id is <name>-<key>. Lowercase letters, digits and hyphens, at most 40 characters. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project that owns the secrets. | `string` | n/a | yes |
| <a name="input_create"></a> [create](#input\_create) | Whether to create any resources. Set false to create nothing. | `bool` | `true` | no |
| <a name="input_kms_key_name"></a> [kms\_key\_name](#input\_kms\_key\_name) | Customer-managed encryption key (projects/.../cryptoKeys/...) applied to every secret. For user-managed replication the key must be usable in every replica location. Null uses Google-managed encryption. | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels merged onto every secret, applied last. | `map(string)` | `{}` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | Map of secret key to settings. value: initial secret version, stored in Terraform state. create\_version: plan-known switch (default true) for creating the version; set false for a secret without a version, and true requires a non-null value. replication\_locations: null or empty means automatic replication, otherwise user-managed replicas in those locations. accessor\_members: IAM members granted roles/secretmanager.secretAccessor on that secret. Keys are at most 20 characters of letters, digits, underscore and hyphen. | <pre>map(object({<br/>    value                 = optional(string)<br/>    create_version        = optional(bool, true)<br/>    replication_locations = optional(list(string))<br/>    accessor_members      = optional(list(string), [])<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | Map of secrets key to secret id (<name>-<key>). Null when create is false. |
| <a name="output_labels"></a> [labels](#output\_labels) | Labels applied to every secret, with context.extra\_tags merged in. Null when create is false. |
| <a name="output_name"></a> [name](#output\_name) | Prefix used for secret ids (var.name). Null when create is false. |
| <a name="output_secret_ids"></a> [secret\_ids](#output\_secret\_ids) | Map of secrets key to secret id (<name>-<key>). Null when create is false. |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | Map of secrets key to full resource name (projects/<project>/secrets/<id>). Null when create is false. |
| <a name="output_version_names"></a> [version\_names](#output\_version\_names) | Map of secrets key to secret version resource name, only for keys that were given a value. Null when create is false. |
<!-- END_TF_DOCS -->

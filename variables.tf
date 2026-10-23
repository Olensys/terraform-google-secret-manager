variable "name" {
  description = "Prefix for secret ids; each secret id is <name>-<key>. Lowercase letters, digits and hyphens, at most 40 characters."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,40}$", var.name))
    error_message = "name must match ^[a-z0-9-]{1,40}$."
  }
}

variable "context" {
  description = "Deployment context used for naming, tagging and environment-dependent defaults."
  type = object({
    organization = string
    environment  = string
    application  = string
    component    = optional(string)
    owner        = string
    cost_center  = string
    extra_tags   = optional(map(string), {})
  })
  validation {
    condition     = contains(["dev", "staging", "prod", "test", "shared"], var.context.environment)
    error_message = "context.environment must be one of dev, staging, prod, test, shared."
  }
}

variable "project_id" {
  description = "GCP project that owns the secrets."
  type        = string
}

variable "create" {
  description = "Whether to create any resources. Set false to create nothing."
  type        = bool
  default     = true
}

variable "secrets" {
  description = "Map of secret key to settings. value: initial secret version (null creates the secret without a version; the value is stored in Terraform state). replication_locations: null means automatic replication, otherwise user-managed replicas in those locations. accessor_members: IAM members granted roles/secretmanager.secretAccessor on that secret. Keys are at most 20 characters of letters, digits, underscore and hyphen."
  type = map(object({
    value                 = optional(string)
    replication_locations = optional(list(string))
    accessor_members      = optional(list(string), [])
  }))
  default   = {}
  sensitive = true
  validation {
    condition     = alltrue([for k in nonsensitive(keys(var.secrets)) : can(regex("^[a-zA-Z0-9_-]{1,20}$", k))])
    error_message = "Every key in secrets must match ^[a-zA-Z0-9_-]{1,20}$."
  }
}

variable "kms_key_name" {
  description = "Customer-managed encryption key (projects/.../cryptoKeys/...) applied to every secret. For user-managed replication the key must be usable in every replica location. Null uses Google-managed encryption."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels merged onto every secret, applied last."
  type        = map(string)
  default     = {}
}

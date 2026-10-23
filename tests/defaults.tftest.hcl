mock_provider "google" {}

variables {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
  name       = "app"
  project_id = "example-project"
  secrets = {
    db  = { value = "s3cret" }
    api = {}
  }
}

run "test_secret_per_key" {
  command = plan

  assert {
    condition     = length(google_secret_manager_secret.this) == 2
    error_message = "One secret per map key."
  }

  assert {
    condition     = google_secret_manager_secret.this["db"].secret_id == "app-db" && google_secret_manager_secret.this["api"].secret_id == "app-api"
    error_message = "Secret ids must be <name>-<key>."
  }

  assert {
    condition     = output.secret_ids["db"] == "app-db" && output.id["api"] == "app-api" && output.name == "app"
    error_message = "Outputs must expose the secret ids and the name prefix."
  }
}

run "test_version_only_when_value" {
  command = plan

  assert {
    condition     = length(google_secret_manager_secret_version.this) == 1
    error_message = "Only keys with a value get a version."
  }

  assert {
    condition     = contains(keys(google_secret_manager_secret_version.this), "db") && !contains(keys(google_secret_manager_secret_version.this), "api")
    error_message = "db has a version, api does not."
  }
}

run "test_accessor_iam" {
  command = plan

  variables {
    secrets = {
      db = { value = "x", accessor_members = ["serviceAccount:a@example-project.iam.gserviceaccount.com", "group:b@example.com"] }
      api = {
        accessor_members = ["group:b@example.com"]
      }
    }
  }

  assert {
    condition     = length(google_secret_manager_secret_iam_member.accessor) == 3
    error_message = "One binding per (secret, member) pair."
  }

  assert {
    condition     = google_secret_manager_secret_iam_member.accessor["api/group:b@example.com"].role == "roles/secretmanager.secretAccessor"
    error_message = "Accessors get roles/secretmanager.secretAccessor."
  }
}

run "test_replication_automatic_default" {
  command = plan

  assert {
    condition     = length(google_secret_manager_secret.this["db"].replication[0].auto) == 1 && length(google_secret_manager_secret.this["db"].replication[0].user_managed) == 0
    error_message = "Replication must be automatic when replication_locations is null."
  }
}

run "test_replication_user_managed_when_locations" {
  command = plan

  variables {
    secrets = {
      db = { value = "x", replication_locations = ["europe-west1", "europe-west4"] }
    }
  }

  assert {
    condition     = length(google_secret_manager_secret.this["db"].replication[0].auto) == 0 && length(google_secret_manager_secret.this["db"].replication[0].user_managed[0].replicas) == 2
    error_message = "One replica per location with user-managed replication."
  }
}

run "test_create_false_plans_nothing" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition     = output.id == null && output.name == null && output.self_link == null && output.secret_ids == null && output.version_names == null && output.labels == null
    error_message = "All outputs must be null when create is false."
  }

  assert {
    condition     = length(google_secret_manager_secret.this) == 0 && length(google_secret_manager_secret_version.this) == 0 && length(google_secret_manager_secret_iam_member.accessor) == 0
    error_message = "No resources when create is false."
  }
}

run "test_name_length_validation" {
  command = plan

  variables {
    name = "abcdefghijklmnopqrstuvwxyzabcdefghijklmno"
  }

  expect_failures = [var.name]
}

run "test_key_format_validation" {
  command = plan

  variables {
    secrets = {
      "bad key!" = {}
    }
  }

  expect_failures = [var.secrets]
}

run "test_tags_contract" {
  command = plan

  variables {
    labels = { owner = "x" }
    context = {
      organization = "olensys"
      environment  = "test"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
      extra_tags   = { owner = "y", team = "z" }
    }
  }

  assert {
    condition     = output.labels.owner == "x"
    error_message = "var.labels must win over extra_tags."
  }

  assert {
    condition     = output.labels.team == "z"
    error_message = "extra_tags must be merged."
  }
}

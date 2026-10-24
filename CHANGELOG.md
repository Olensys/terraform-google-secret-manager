# Changelog

## [1.1.2](https://github.com/Olensys/terraform-google-secret-manager/compare/v1.1.1...v1.1.2) (2026-10-24)


### Bug Fixes

* **examples:** unique application slug so concurrent integration runs do not collide ([#2](https://github.com/Olensys/terraform-google-secret-manager/issues/2)) ([60475a8](https://github.com/Olensys/terraform-google-secret-manager/commit/60475a8fd14b5e45c972f927bd511c8c178a6a7b))

## [1.1.1](https://github.com/Olensys/terraform-google-secret-manager/compare/v1.1.0...v1.1.1) (2026-10-24)


### Bug Fixes

* **examples:** pin naming module to v1.0.1 ([5e1a3e5](https://github.com/Olensys/terraform-google-secret-manager/commit/5e1a3e5e06ca062e2d4fea661b342f9546bbba4f))
* run integration on change and weekly instead of nightly ([12e0de9](https://github.com/Olensys/terraform-google-secret-manager/commit/12e0de982e7943dc4331eae037ebe3da9cdcea0c))

## 1.1.0

### Fixes

- normalise `context.extra_tags` keys and values to valid GCP label syntax (lowercase, `[^a-z0-9_-]` replaced by `-`, 63 characters); `labels` are applied verbatim and win

### Tests

- `test_tags_contract` now covers mixed-case extra tags and verifies normalisation

### Docs

- Usage shows the naming module; Opinions describe label normalisation

### Behaviour changes

- `labels` output and applied labels now contain normalised keys and values for `context.extra_tags` (for example `Team = "Core Team"` becomes `team = "core-team"`). Callers that relied on mixed-case or space-containing extra tags must expect the normalised form; values passed in `labels` are unchanged.

## 1.0.1

### Fixes

- plan-known create_version, empty replication list is automatic

## 1.0.0

- Secret Manager secrets from a map: id <name>-<key>, optional initial versions, automatic or user-managed replication, optional CMEK, per-secret accessor IAM.

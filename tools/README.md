# Model Catalog Validator (v0.1)

Lightweight PowerShell validator for the Voice Platform model catalog and distribution tree.
Kept intentionally small; no framework.

## Usage

```powershell
powershell -ExecutionPolicy Bypass -File validate-catalog.ps1 `
    -CatalogPath ..\catalog\models.json `
    -DistributionRoot ..\
```

## Behaviour

The validator **separates** two concerns:

1. **Catalog metadata validity** (schema/consistency) — failures are ERRORS and set the exit code to 1.
2. **Artifact availability** (local file/checksum presence) — reported as WARNINGS, because the tree is
   designed for remote deployment and local file existence is not mandatory.

### Metadata checks (errors)

- JSON is parseable; `schemaVersion == 1`; `models` is an array.
- Entry required fields present and non-empty: `id`, `version`, `type`, `language`.
- `type` is `stt` or `tts`.
- Entry identity is unique per `(type, language, id, version)`.
- `publishable == true` requires: real `sha256` (64 hex), positive `sizeBytes`, and an `artifact.path`.
- Any present `sha256` must be 64 hex; `sizeBytes` (if present) must be a non-negative integer.
- `preview.source` is `bundled` or `remote` when `preview` is present.
- `distribution.allowedAppIds` (when present) is an array of non-empty strings.
- Language independence is structural: no cross-language requirement is inferred.

### Availability checks (warnings)

- For each `publishable == true` entry with an `artifact.path`, if the file exists under
  `-DistributionRoot`, its SHA-256 is compared with the entry `sha256` (mismatch is an ERROR; a
  missing local file is a WARNING).
- For each `preview.source == "remote"` entry with a `preview.path`, a missing local file is a WARNING
  (remote deployment is allowed).

## Exit codes

- `0` — metadata valid (warnings may exist).
- `1` — metadata/consistency error, or a checksum mismatch on a locally present publishable artifact.

Use `-TreatWarningsAsErrors` to fail on warnings too (useful for CI publishing checks).

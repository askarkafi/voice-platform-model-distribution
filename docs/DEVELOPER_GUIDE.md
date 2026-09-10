# Developer Guide — Voice Platform Model Distribution

## 1. Purpose

This repository is the public distribution point for Voice Platform model
catalog metadata, schemas, documentation, previews, and downloadable model
artifacts.

It is intentionally separate from the private Voice Platform source
repository.

The current structure is a bootstrap distribution structure. It should remain
simple and can evolve when real integration requirements become clear.

## 2. Repository

Public repository:

`https://github.com/askarkafi/voice-platform-model-distribution`

Current model release:

`models-v0.1.0`

Release page:

`https://github.com/askarkafi/voice-platform-model-distribution/releases/tag/models-v0.1.0`

## 3. Current structure

```text
voice-platform-model-distribution/
├── README.md
├── catalog/
│   ├── models.json
│   └── schema/
│       └── models.schema.json
├── previews/
│   ├── stt/
│   │   ├── fa/
│   │   └── en/
│   └── tts/
│       ├── fa/
│       └── en/
├── tools/
│   └── validate-catalog.ps1
└── docs/
    └── distribution.md
```

### `catalog/`

The catalog is the metadata source for available models.

- `models.json` describes the models and their distribution artifacts.
- `schema/models.schema.json` defines the expected catalog structure.

The catalog is the important integration contract. Consumers should use the
catalog rather than hard-coding individual model URLs.

### `previews/`

Small preview files used to demonstrate or validate model behavior.

They are organized by model type and language:

- `previews/stt/fa/`
- `previews/stt/en/`
- `previews/tts/fa/`
- `previews/tts/en/`

### `tools/`

Small maintenance/validation utilities.

The current validator performs lightweight catalog checks. It is not intended
to replace a full JSON Schema validation system.

### `docs/`

Distribution documentation and future integration notes.

## 4. Where model files go

Large model packages do **not** belong in the normal Git repository.

The intended current distribution is:

```text
Git repository
├── catalog / schema
├── documentation
├── validation tools
└── small preview files

GitHub Release Assets
└── large model packages
```

For example:

```text
Release: models-v1.0.0
└── stt-fa-small-1.0.0.zip
```

The model package is a distribution artifact. Its internal runtime format may
be different from the ZIP/container format used for distribution.

## 5. Catalog-driven consumption

A consumer such as the Voice Platform should:

1. Read `catalog/models.json`.
2. Select a compatible model using its metadata.
3. Read the artifact URL from the selected catalog entry.
4. Download the artifact from that URL.
5. Verify the downloaded artifact using its declared SHA-256 when available.
6. Install/extract/use the model according to the Voice Platform's runtime
   requirements.

Do not hard-code GitHub Release URLs in application code.

The catalog should be the source used to discover the current artifact URL.

## 6. Model identity and versioning

Model identity and model version are separate concepts.

Example:

```text
modelId: stt-fa-small
version: 1.0.0
```

A corresponding distribution filename could be:

```text
stt-fa-small-1.0.0.zip
```

Release tags may follow the repository's model-release convention, for example:

```text
models-v1.0.0
```

## 7. Integrity

When a model artifact has a SHA-256 value in the catalog, the checksum must be
calculated over the exact distributed artifact file.

For example, if the catalog points to:

```text
stt-fa-small-1.0.0.zip
```

the SHA-256 must be the checksum of that ZIP file, not of an extracted model
directory or one of the files inside it.

## 8. `allowedAppIds`

If a catalog entry contains `allowedAppIds`, treat it as distribution/policy
metadata.

It is **not a security boundary** and must not be treated as authorization,
authentication, or DRM.

Any real entitlement or access-control mechanism belongs outside this public
catalog.

## 9. Storage independence

The current implementation uses GitHub because it is simple and appropriate
for bootstrapping.

The consumer architecture should not depend on GitHub-specific paths.

A future setup may move artifacts and previews to object storage/CDN, for
example:

```text
Catalog -> GitHub or CDN
Models  -> Object Storage / CDN
Previews -> Object Storage / CDN
```

The catalog-driven design allows this migration without requiring the consumer
to redesign its model-discovery logic.

## 10. Expected developer behavior

When adding a new model:

- Add/update its catalog entry.
- Follow the existing schema.
- Put large distribution artifacts in a GitHub Release Asset, not normal Git
  history.
- Add previews only when useful/available.
- Record the exact artifact URL and checksum in the catalog.
- Keep model IDs stable and use the version field for model revisions.
- Avoid introducing application-specific runtime logic into this repository.

The exact directory structure is currently a practical bootstrap structure, not
a permanent architectural constraint. Limited changes are acceptable when
integration requirements justify them, but unnecessary infrastructure should
not be added at this stage.

# Voice Platform Model Distribution

Public distribution repository for downloadable voice models and previews used by Voice Platform.

## Purpose

This repository contains the static model catalog, catalog schema, small preview assets, validation tools, and distribution documentation.

Large model packages are distributed as GitHub Release Assets and are intentionally not committed to Git.

## Repository layout

```text
catalog/
├── models.json
└── schema/
    └── models.schema.json

previews/
├── stt/
│   ├── fa/
│   └── en/
└── tts/
    ├── fa/
    └── en/

tools/
└── validate-catalog.ps1

docs/
└── distribution.md
```

## Distribution model

The catalog is the contract consumed by Voice Platform. Artifact and preview locations are URL-based so the storage implementation can later migrate from GitHub Releases to object storage/CDN without changing the consumer architecture.

Large model packages belong in GitHub Releases as release assets, not in the Git repository.

# Developer Quick Guide

This repository is the **public distribution layer** for Voice Platform models.
The Voice Platform source code remains in a separate private repository.

## Current layout

- `catalog/models.json` — catalog of available models and their artifact metadata.
- `catalog/schema/models.schema.json` — catalog schema.
- `previews/` — small STT/TTS preview files.
- `tools/` — lightweight catalog validation tools.
- `docs/` — distribution documentation.
- **Large model packages** — stored as **GitHub Release Assets**, not committed
  to normal Git history.

## Current release

`models-v0.1.0`

Large model files will be attached to releases as they become available.

## Important integration rule

Consumers should read model artifact URLs from `catalog/models.json`.

**Do not hard-code GitHub Release URLs in application code.**

The current GitHub-based storage is an implementation choice for the bootstrap
stage. The distribution layer may later move model files/previews to object
storage or a CDN without changing the catalog-driven consumer approach.

See [`docs/DEVELOPER_GUIDE.md`](./docs/DEVELOPER_GUIDE.md) for the full developer
guidance.


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

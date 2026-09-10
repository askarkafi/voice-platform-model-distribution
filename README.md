# Voice Platform — Model Distribution Tree

Static, deployment-oriented distribution of speech models/voices for the Voice Platform
(`catalog v0.1`). This tree is **independent of the app source tree**: it is copied as-is to a web
server / object storage / CDN and consumed by consumer apps (Reference App first).

## Status (important)

- **No artifact is publishable yet.** All entries in `catalog/models.json` are marked
  `"publishable": false` and are **example/planned** entries. Where an identifier is observed in the
  consumer repositories it is used verbatim (Persian); entries without repository evidence (English)
  are explicitly labelled illustrative. **No checksum is fabricated** — `sha256` is required only for
  publishable artifacts.
- Per ADR-0015, **model files are not committed to this repository** during P5. Real artifact bytes
  will be published into this tree by the P5.2+ publishing workflow, not committed here.

## Tree

```text
model-distribution/
├── catalog/
│   ├── models.json                 # catalog v0.1
│   └── catalog.schema.v0.1.json    # JSON Schema (documentation/validation reference)
├── previews/
│   ├── stt/                        # short audio samples demonstrating an STT model (future)
│   └── tts/                        # voice previews (e.g. fa_IR-ganji-medium.preview.mp3)
└── packages/
    ├── stt/
    │   ├── fa/                     # Persian STT runtime artifact(s)
    │   └── en/                     # English STT runtime artifact(s)
    └── tts/
        ├── fa/                     # Persian voices (independent per voice)
        └── en/                     # English voices (independent per voice)
```

Directory layout is conventional, not normative: the catalog references artifacts by **relative
path**, so the tree shape may evolve without breaking consumers that resolve via the catalog.

## Deployment (static hosting)

Copy the directory to a server/object store/CDN:

```text
COPY DIRECTORY model-distribution/  →  https://your-cdn/models/
```

No backend is required. Consumers resolve artifacts **relative to a consumer-configured base URL**,
never a hard-coded production host. Conceptual consumer configuration (provided by the app, not this
tree):

```text
MODEL_CATALOG_URL           = <catalog base>/catalog/models.json
MODEL_DISTRIBUTION_BASE_URL = <distribution base>/   (packages + previews root)
```

## Semantics

- **Bilingual independence (fa / en):** each language/voice is an independent catalog entry and an
  independent artifact. Selecting English never downloads Persian assets and vice-versa.
- **Runtime format ≠ distribution format:** distributed files are the runtime formats (Vosk model
  dir; Piper `.onnx` + `tokens.txt` + `espeak-ng-data`) packaged as immutable files; no conversion is
  performed for distribution.
- **Integrity:** every publishable artifact has a real SHA-256 in the catalog, verified at download
  time (P5.3).
- **Previews:** preview audio is separate from the model package so a user can listen before
  downloading a full model. `preview.source` = `"bundled"` (ships with app) or `"remote"` (relative
  path in this tree).
- **`allowedAppIds` is DISTRIBUTION POLICY, NOT SECURITY.** It answers "which applications is this
  artifact offered to?" It does **not** answer "is this request authenticated and authorized?".
  Entitlement/authentication is a future, separate concern.
- **Not Core:** a catalog entry is distribution metadata; it is not a Core runtime contract and is
  unrelated to the Core `Voice` value type (which is unchanged).

## Validation

```text
powershell -ExecutionPolicy Bypass -File model-distribution/tools/validate-catalog.ps1 `
    -CatalogPath model-distribution/catalog/models.json `
    -DistributionRoot model-distribution
```

The validator separates **catalog metadata validity** (schema/consistency; errors fail the run) from
**artifact availability** (local file/checksum checks; reported as warnings, since this tree is
designed for remote deployment).

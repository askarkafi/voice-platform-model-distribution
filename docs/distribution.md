# Model Distribution

## Scope

The Model Distribution repository is the public distribution layer for Voice Platform voice models.

It is intentionally separate from the private Voice Platform source repository.

## Responsibilities

This repository owns:

- Static model catalog
- Catalog schema
- Small preview assets
- Distribution documentation
- Catalog validation tooling

It does not own:

- Voice Platform application source code
- Runtime model loading logic
- Authentication
- Entitlements
- Payments
- Backend APIs
- Security enforcement
- Large model packages inside Git history

## Artifact distribution

Model packages are distributed as GitHub Release Assets.

The catalog points to the artifact through:

```text
artifact.url
artifact.path
artifact.sizeBytes
artifact.sha256
```

The ZIP/package format is a distribution format. It must not be assumed to be the runtime model format.

## Preview distribution

Previews are independently addressable from the model package. A preview can therefore be replaced or migrated without changing the model package contract.

## Consumer flow

```text
GET catalog
    |
    v
Select model
    |
    v
Read artifact.url
    |
    v
Download artifact
    |
    v
Verify SHA-256
    |
    v
Install into Local Model Store
```

The consumer should use the URLs supplied by the catalog rather than hard-coding GitHub URLs.

## Future storage migration

Initial implementation:

```text
Catalog        -> GitHub repository
Model packages -> GitHub Releases
Previews       -> GitHub repository
```

Future implementation may use:

```text
Catalog        -> GitHub or CDN
Model packages -> R2/object storage/CDN
Previews       -> object storage/CDN
```

The distribution contract remains URL-based so the Voice Platform architecture does not depend on a specific storage provider.

## Policy note

`allowedAppIds`, when used, is distribution policy metadata. It is not an authentication or security mechanism.

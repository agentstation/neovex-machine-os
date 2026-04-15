# neovex-machine-os

Guest OS image for the neovex macOS developer machine. Built on Fedora bootc
with neovex and container tooling pre-installed.

This is the neovex equivalent of
[containers/podman-machine-os](https://github.com/containers/podman-machine-os).

## What's inside

The guest image includes:

- **neovex** — the neovex server binary (from `agentstation/neovex` releases)
- **Container tooling** — crun, conmon, buildah, containers-common, netavark,
  aardvark-dns, fuse-overlayfs, catatonit, passt
- **System services** — openssh-server, socat, cloud-init

The image is built from `quay.io/fedora/fedora-bootc:42` and converted to a
raw disk image via `bootc-image-builder`.

## Published artifacts

| Artifact | Location |
|----------|----------|
| Raw-disk OCI image | `ghcr.io/agentstation/neovex-machine-os` |
| Build provenance | GitHub Attestations (via `actions/attest`) |

## Building locally

Requires a Linux host with podman and root access:

```bash
# Download a neovex binary first
curl -fsSL -o /tmp/neovex_linux_arm64.tar.gz \
  https://github.com/agentstation/neovex/releases/latest/download/neovex_linux_arm64.tar.gz
tar xzf /tmp/neovex_linux_arm64.tar.gz -C /tmp

sudo bash scripts/build.sh \
  --neovex-binary /tmp/neovex \
  --neovex-version vX.Y.Z \
  --output-dir /tmp/neovex-machine-os
```

`--neovex-version` is optional for ad hoc local builds, but release and CI
lanes should pass it so the build summary and packaged OCI metadata record the
embedded Neovex version explicitly.

## CI

The GitHub Actions workflow (`.github/workflows/build.yml`) runs on
`ubuntu-24.04-arm` and:

1. **verify-contract** — script syntax, help entrypoints, deterministic
   helper tests
2. **build-arm64** — downloads or receives the matching neovex Linux binary,
   builds the guest image, packages it as OCI layout, publishes to GHCR on
   `v*` tags, and attests the build output

Primary release path:

- `agentstation/neovex` `v*` releases call this workflow via `workflow_call`
  and pass the same tag as `neovex_version`
- standalone `agentstation/neovex-machine-os` `v*` tags are expected to use
  the same `v*` tag as the embedded neovex release; the workflow resolves the
  binary from `agentstation/neovex/releases/download/<same-tag>/...`
- non-release validation runs may float to Neovex's latest published release,
  but they do not publish immutable artifacts

Published OCI metadata includes:

- `org.opencontainers.image.source=https://github.com/agentstation/neovex-machine-os`
- `io.neovex.machine.attestation.repository=<repo that owns the attestation>`
- `io.neovex.machine.neovex.version=<embedded neovex tag>`

Triggered by pushes to main (path-filtered), `v*` tags, `workflow_call`, and
`workflow_dispatch`.

## License

See [LICENSE](LICENSE).

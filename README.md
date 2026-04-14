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
curl -fsSL -o /tmp/neovex \
  https://github.com/agentstation/neovex/releases/latest/download/neovex_linux_arm64.tar.gz

sudo bash scripts/build.sh \
  --neovex-binary /tmp/neovex \
  --output-dir /tmp/neovex-machine-os
```

## CI

The GitHub Actions workflow (`.github/workflows/build.yml`) runs on
`ubuntu-24.04-arm` and:

1. **verify-contract** — script syntax, help entrypoints, deterministic
   helper tests
2. **build-arm64** — downloads the neovex binary from GitHub Releases,
   builds the guest image, packages as OCI layout, publishes to GHCR on
   `v*` tags with attestation

Triggered by pushes to main (path-filtered), `v*` tags, and
`workflow_dispatch`.

## License

See [LICENSE](LICENSE).

#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
recipe_dir="${repo_root}/images"
temp_dir="$(mktemp -d)"
trap 'rm -rf "${temp_dir}"' EXIT

bash -n "${recipe_dir}/build.sh"
bash -n "${recipe_dir}/build-common.sh"

grep -F 'FROM ${FCOS_BASE_IMAGE}' "${recipe_dir}/Containerfile" >/dev/null
grep -F 'COPY neovex /usr/local/bin/neovex' "${recipe_dir}/Containerfile" >/dev/null

grep -F 'crun' "${recipe_dir}/build-common.sh" >/dev/null
grep -F 'conmon' "${recipe_dir}/build-common.sh" >/dev/null
grep -F 'buildah' "${recipe_dir}/build-common.sh" >/dev/null
grep -F 'containers-common' "${recipe_dir}/build-common.sh" >/dev/null
grep -F 'netavark' "${recipe_dir}/build-common.sh" >/dev/null
grep -F 'aardvark-dns' "${recipe_dir}/build-common.sh" >/dev/null
grep -F 'openssh-server' "${recipe_dir}/build-common.sh" >/dev/null
grep -F 'socat' "${recipe_dir}/build-common.sh" >/dev/null
grep -F 'dnf remove -y moby-engine containerd runc toolbox docker-cli' "${recipe_dir}/build-common.sh" >/dev/null

test -f "${recipe_dir}/bootc-image-builder.toml"
grep -F 'minsize' "${recipe_dir}/bootc-image-builder.toml" >/dev/null
grep -F 'ostree.prepare-root.composefs=0' "${recipe_dir}/bootc-image-builder.toml" >/dev/null

fake_bin="${temp_dir}/bin"
context_dir="${temp_dir}/context"
output_dir="${temp_dir}/out"
mkdir -p "${fake_bin}" "${context_dir}" "${output_dir}"

cat >"${fake_bin}/podman" <<'FAKEOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${TMPDIR}/podman.log"
# Handle `podman save --format oci-archive -o <path> <image>`
if [[ "${1:-}" == "save" ]]; then
  for i in "$@"; do
    case "${prev:-}" in
      -o) mkdir -p "$(dirname "$i")"; : >"$i" ;;
    esac
    prev="$i"
  done
fi
# Handle `podman run ... bootc-image-builder ... --type raw`
if [[ "${1:-}" == "run" ]]; then
  for i in "$@"; do
    if [[ "${prev:-}" == "-v" && "$i" == *:/output ]]; then
      bib_out="${i%%:*}"
      mkdir -p "${bib_out}/image"
      : >"${bib_out}/image/disk.raw"
    fi
    prev="$i"
  done
fi
exit 0
FAKEOF

chmod 0755 "${fake_bin}/podman"

neovex_binary="${temp_dir}/neovex"
cat >"${neovex_binary}" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod 0755 "${neovex_binary}"

TMPDIR="${temp_dir}" \
PATH="${fake_bin}:${PATH}" \
NEOVEX_MACHINE_OS_BUILD_TEST_UNAME=Linux \
NEOVEX_MACHINE_OS_BUILD_TEST_UID=0 \
bash "${recipe_dir}/build.sh" \
  --neovex-binary "${neovex_binary}" \
  --neovex-version v1.2.3 \
  --output-dir "${output_dir}" \
  --context-dir "${context_dir}"

test -f "${output_dir}/neovex-machine-os.ociarchive"
test -f "${output_dir}/neovex-machine-os.raw.gz"
test -f "${output_dir}/summary.txt"
grep -F -- '--build-arg FCOS_BASE_IMAGE=' "${temp_dir}/podman.log" >/dev/null
grep -F -- 'save --format oci-archive' "${temp_dir}/podman.log" >/dev/null
grep -F -- 'bootc-image-builder' "${temp_dir}/podman.log" >/dev/null
grep -F -- '--type raw' "${temp_dir}/podman.log" >/dev/null
grep -E '^neovex_binary_sha256=[0-9a-f]{64}$' "${output_dir}/summary.txt" >/dev/null
grep -F 'neovex_version=v1.2.3' "${output_dir}/summary.txt" >/dev/null
grep -E '^containerfile_sha256=[0-9a-f]{64}$' "${output_dir}/summary.txt" >/dev/null
grep -E '^build_common_sha256=[0-9a-f]{64}$' "${output_dir}/summary.txt" >/dev/null
grep -E '^oci_archive_sha256=[0-9a-f]{64}$' "${output_dir}/summary.txt" >/dev/null
grep -E '^compressed_raw_disk_sha256=[0-9a-f]{64}$' "${output_dir}/summary.txt" >/dev/null
grep -F 'compressed_raw_disk_path=' "${output_dir}/summary.txt" >/dev/null
gzip -dc "${output_dir}/neovex-machine-os.raw.gz" >/dev/null
test -f "${context_dir}/neovex"

printf 'verified neovex machine-os recipe\n'

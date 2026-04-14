#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: build.sh --neovex-binary <path> [options]

Build the neovex-machine-os guest image on a Linux host using the checked-in
image recipe and a pre-built Linux neovex binary.

Options:
  --neovex-binary <path>              Linux neovex binary to install into the guest (required)
  --output-dir <path>                 Output directory passed through to the image recipe
  --image-name <reference>            OCI tag passed through to the image recipe
  --fcos-base-image <reference>       Base image passed through to the image recipe
  --context-dir <path>                Reused staging context passed through to the image recipe
  -h, --help                          Show this help

Examples:
  sudo bash scripts/build.sh \
    --neovex-binary /path/to/neovex-linux-aarch64 \
    --output-dir /tmp/neovex-machine-os
EOF
}

require_command() {
  local command_name="$1"
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "required command not found: ${command_name}" >&2
    exit 69
  fi
}

neovex_binary=""
output_dir=""
image_name=""
fcos_base_image=""
context_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --neovex-binary)
      neovex_binary="${2:-}"
      shift 2
      ;;
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --image-name)
      image_name="${2:-}"
      shift 2
      ;;
    --fcos-base-image)
      fcos_base_image="${2:-}"
      shift 2
      ;;
    --context-dir)
      context_dir="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

os_name="${NEOVEX_MACHINE_OS_BUILD_WRAPPER_TEST_UNAME:-$(uname -s)}"
if [[ "${os_name}" != "Linux" ]]; then
  echo "build.sh requires a Linux host" >&2
  exit 69
fi

if [[ -z "${neovex_binary}" ]]; then
  echo "--neovex-binary is required" >&2
  usage >&2
  exit 64
fi

require_command bash

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
recipe_script="${repo_root}/images/build.sh"

if [[ ! -f "${recipe_script}" ]]; then
  echo "image recipe entrypoint not found: ${recipe_script}" >&2
  exit 66
fi

if [[ ! -f "${neovex_binary}" ]]; then
  echo "neovex binary not found: ${neovex_binary}" >&2
  exit 66
fi

echo "build.neovex_binary=${neovex_binary}"
echo "build.recipe=${recipe_script}"

args=(--neovex-binary "${neovex_binary}")
if [[ -n "${output_dir}" ]]; then
  args+=(--output-dir "${output_dir}")
fi
if [[ -n "${image_name}" ]]; then
  args+=(--image-name "${image_name}")
fi
if [[ -n "${fcos_base_image}" ]]; then
  args+=(--fcos-base-image "${fcos_base_image}")
fi
if [[ -n "${context_dir}" ]]; then
  args+=(--context-dir "${context_dir}")
fi

bash "${recipe_script}" "${args[@]}"

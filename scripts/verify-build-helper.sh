#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${repo_root}/scripts/test-helpers.sh"
temp_dir="$(mktemp -d)"
trap 'rm -rf "${temp_dir}"' EXIT

fake_bin="${temp_dir}/bin"
mkdir -p "${fake_bin}"

# Create a fake neovex binary
write_noop_executable "${temp_dir}/neovex"

# Create a fake bash that intercepts the recipe script call
write_executable_stub "${fake_bin}/bash" <<'EOF'
#!/bin/bash
set -euo pipefail
if [[ "${1:-}" == *"images/build.sh" ]]; then
  shift
  printf '%s\n' "$*" >>"${TMPDIR}/recipe.log"
  exit 0
fi
exec /bin/bash "$@"
EOF

PATH="${fake_bin}:${PATH}" \
TMPDIR="${temp_dir}" \
NEOVEX_MACHINE_OS_BUILD_WRAPPER_TEST_UNAME=Linux \
bash "${repo_root}/scripts/build.sh" \
  --neovex-binary "${temp_dir}/neovex" \
  --neovex-version v1.2.3 \
  --output-dir /tmp/neovex-machine-os-out

grep -F -- '--neovex-binary' "${temp_dir}/recipe.log" >/dev/null
grep -F -- '--neovex-version v1.2.3' "${temp_dir}/recipe.log" >/dev/null
grep -F -- '--output-dir /tmp/neovex-machine-os-out' "${temp_dir}/recipe.log" >/dev/null

printf 'verified neovex machine-os build wrapper\n'

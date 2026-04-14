#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_dir="$(mktemp -d)"
trap 'rm -rf "${temp_dir}"' EXIT

fake_bin="${temp_dir}/bin"
mkdir -p "${fake_bin}"

# Create a fake neovex binary
printf '#!/usr/bin/env bash\nexit 0\n' >"${temp_dir}/neovex"
chmod 0755 "${temp_dir}/neovex"

# Create a fake bash that intercepts the recipe script call
cat >"${fake_bin}/bash" <<'EOF'
#!/bin/bash
set -euo pipefail
if [[ "${1:-}" == *"images/build.sh" ]]; then
  shift
  printf '%s\n' "$*" >>"${TMPDIR}/recipe.log"
  exit 0
fi
exec /bin/bash "$@"
EOF

chmod 0755 "${fake_bin}/bash"

PATH="${fake_bin}:${PATH}" \
TMPDIR="${temp_dir}" \
NEOVEX_MACHINE_OS_BUILD_WRAPPER_TEST_UNAME=Linux \
bash "${repo_root}/scripts/build.sh" \
  --neovex-binary "${temp_dir}/neovex" \
  --output-dir /tmp/neovex-machine-os-out

grep -F -- '--neovex-binary' "${temp_dir}/recipe.log" >/dev/null
grep -F -- '--output-dir /tmp/neovex-machine-os-out' "${temp_dir}/recipe.log" >/dev/null

printf 'verified neovex machine-os build wrapper\n'

#!/usr/bin/env bash

write_executable_stub() {
  local target="$1"
  local parent base temp
  parent="$(dirname "$target")"
  base="$(basename "$target")"
  mkdir -p "$parent"
  temp="$(mktemp "${parent}/.${base}.tmp.XXXXXX")"
  cat >"${temp}"
  chmod 0755 "${temp}"
  mv -f "${temp}" "${target}"
}

write_noop_executable() {
  write_executable_stub "$1" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
}

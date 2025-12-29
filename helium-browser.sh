#!/bin/bash
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"

SYS_CONF="/etc/helium-browser-flags.conf"
USR_CONF="${XDG_CONFIG_HOME}/helium-browser-flags.conf"

FLAGS=()

append_flags_file() {
  local file="$1"
  [[ -r "$file" ]] || return 0
  local line safe_line
  # Filter comments & blank lines
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    # Sanitise: block command substitution; prevent $VAR and ~ expansion
    case "$line" in
      *'$('*|*'`'*)
        echo "Warning: ignoring unsafe line in $file: $line" >&2
        continue
        ;;
    esac
    # Disable globbing during eval
    set -f
    # Prevent $VAR and ~ expansion while allowing eval to parse quotes & escapes
    safe_line=${line//$/\\$}
    safe_line=${safe_line//~/\\~}
    eval "set -- $safe_line"
    # Enable globbing for rest of the script
    set +f
    for token in "$@"; do
      FLAGS+=("$token")
    done
  done < "$file"
}

append_flags_file "$SYS_CONF"
append_flags_file "$USR_CONF"

# Add environment var $HELIUM_USER_FLAGS
if [[ -n "${HELIUM_USER_FLAGS:-}" ]]; then
  # Split env contents on whitespace; users can quote if needed.
  read -r -a ENV_FLAGS <<< "$HELIUM_USER_FLAGS"
  FLAGS+=("${ENV_FLAGS[@]}")
fi

export CHROME_VERSION_EXTRA="stable"

exec /opt/helium-browser-bin/chrome "${FLAGS[@]}" "$@"


# Maintainer: Sam Sinclair <sam at playleft dot com>
# Contributor: Pujan Modha <pujan.pm@hotmail.com>
# Contributor: init_harsh
# /*
#  * SPDX-FileCopyrightText: 2025 Arch Linux Contributors
#  *
#  * SPDX-License-Identifier: 0BSD
#  */
_pkgname="helium"
pkgname="${_pkgname}-browser-bin"
_binaryname="helium-browser"
pkgver=0.5.8.1
_tarball="${_pkgname}-${pkgver}-x86_64_linux.tar.xz"
pkgrel=1
pkgdesc="Private, fast, and honest web browser based on Chromium"
arch=('x86_64')
url="https://github.com/imputnet/helium-linux"
license=('GPL-3.0-only')
options=('strip')
depends=('gtk3' 'nss' 'alsa-lib' 'xdg-utils' 'libxss' 'libcups' 'libgcrypt'
         'ttf-liberation' 'systemd' 'dbus' 'libpulse' 'pciutils' 'libva'
         'libffi' 'desktop-file-utils' 'hicolor-icon-theme')
optdepends=('pipewire: WebRTC desktop sharing under Wayland'
            'kdialog: support for native dialogs in Plasma'
            'gtk4: for --gtk-version=4 (GTK4 IME might work better on Wayland)'
            'org.freedesktop.secrets: password storage backend on GNOME / Xfce'
            'kwallet: support for storing passwords in KWallet on Plasma'
            'upower: Battery Status API support')
source_x86_64=(
    "${_tarball}::https://github.com/imputnet/helium-linux/releases/download/${pkgver}/${_tarball}"
    "helium.desktop::https://raw.githubusercontent.com/imputnet/helium-linux/${pkgver}/package/helium.desktop"
)

sha256sums_x86_64=('b0e464446600ebf42eeafe8c03e516ae8fb377f6d7883dc0a16e0f80350f5923'
                   'cce8668c18d33077a585cb5d96522e5a02ae017a2baf800f8d7214ce6d05d3d2')
prepare() {
  # Fix upstream desktop file to use the correct binary name and app name
  sed -i \
    -e 's/Exec=chromium/Exec=helium-browser/' \
    -e 's/Name=Helium$/Name=Helium Browser/' \
    -e 's/Icon=helium/Icon=helium-browser/' \
    "${srcdir}/helium.desktop"
}
package() {
  install -dm755 "${pkgdir}/opt/${pkgname}"
  cp -a "${srcdir}/${_pkgname}-${pkgver}-x86_64_linux/"* "${pkgdir}/opt/${pkgname}/"
  # Disable user-local desktop generation in chrome-wrapper
  sed -i 's/exists_desktop_file || generate_desktop_file/true/' \
    "$pkgdir/opt/${pkgname}/chrome-wrapper"
  # Install proper desktop file
  install -Dm644 "${srcdir}/helium.desktop" \
    "${pkgdir}/usr/share/applications/${_binaryname}.desktop"
  # Install icon for desktop file
  install -Dm644 "${pkgdir}/opt/${pkgname}/product_logo_256.png" \
    "${pkgdir}/usr/share/pixmaps/${_binaryname}.png"
  install -Dm644 "${pkgdir}/opt/${pkgname}/product_logo_256.png" \
    "${pkgdir}/usr/share/icons/hicolor/256x256/apps/${_binaryname}.png"
  # Install a simple wrapper
  install -dm755 "${pkgdir}/usr/bin"
  cat > "${pkgdir}/usr/bin/${_binaryname}" << 'EOF'
#!/bin/bash
# Fails on errors or unreadable commands
set -euo pipefail

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

exec /opt/helium-browser-bin/chrome-wrapper "${FLAGS[@]}" "$@"
EOF
  chmod 755 "${pkgdir}/usr/bin/${_binaryname}"
}

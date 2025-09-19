# Maintainer: Sam Sinclair <sam at playleft dot com>
# Contributor: Pujan Modha <pujan.pm@hotmail.com>
# /*
#  * SPDX-FileCopyrightText: 2025 Arch Linux Contributors
#  *
#  * SPDX-License-Identifier: 0BSD
#  */
_pkgname="helium"
pkgname="${_pkgname}-browser-bin"
_binaryname="helium-browser"
pkgver=0.4.7.1
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
  "helium.desktop::https://raw.githubusercontent.com/imputnet/helium-linux/main/package/helium.desktop"
)
sha256sums_x86_64=('1a475cacdfdc900dbaa905a476f5ae82e9d62a30af735b92c456dbc3171b44b2'
                   'e1d22a7fb8ce42d385416b9309abf293711bdc0d95d37e7ca4bbd24d2d27ba35')
prepare() {
  # Fix upstream desktop file to use the correct binary name and app name
  sed -i \
    -e 's/Exec=chromium/Exec=helium-browser/' \
    -e 's/Name=Helium$/Name=Helium Browser/' \
    -e 's/Icon=helium/Icon=helium-browser/' \
    -e '/StartupNotify=/a\StartupWMClass=helium-browser' \
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
exec /opt/helium-browser-bin/chrome-wrapper "$@"
EOF
  chmod 755 "${pkgdir}/usr/bin/${_binaryname}"
}

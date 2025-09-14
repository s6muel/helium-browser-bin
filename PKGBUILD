# Maintainer: Sam Sinclair <sam at playleft dot com>

_pkgname="helium"
pkgname="${_pkgname}-browser-bin"
_binaryname="helium-browser"
pkgver=0.4.6.1
pkgrel=4
pkgdesc="Private, fast, and honest web browser based on Chromium"
arch=('x86_64')
url="https://github.com/imputnet/helium-linux"
license=('GPL3')
depends=('zlib' 'hicolor-icon-theme')
options=(!strip)

_appimage="${_pkgname}-${pkgver}-x86_64.AppImage"

source_x86_64=(
  "${_appimage}::https://github.com/imputnet/helium-linux/releases/download/${pkgver}/${_pkgname}-${pkgver}-x86_64.AppImage"
  "https://raw.githubusercontent.com/imputnet/helium-linux/main/LICENSE"
)
noextract=("${_appimage}")
sha256sums_x86_64=('b725fb77c177ac3999371263f1d75d4fbe737389842de50b718bdd75e6ea81dd'
                   '7056c04df17a4e0f0bac9f787f347c9cd892cee6323d1c89528090afd0b934a3')

prepare() {
  chmod +x "${_appimage}"
  ./"${_appimage}" --appimage-extract
}

build() {
  # Modify desktop file for proper integration
  sed -i -E "s|Exec=AppRun|Exec=${_binaryname}|" "squashfs-root/${_pkgname}.desktop"
  sed -i -E "s|Name=.*|Name=Helium Browser|" "squashfs-root/${_pkgname}.desktop"
  
  # Fix AppImage directory permissions
  chmod -R a-x+rX squashfs-root/usr
}

package() {
  # Install AppImage
  install -Dm755 "${srcdir}/${_appimage}" "${pkgdir}/opt/${pkgname}/${_pkgname}.AppImage"
  
  # Install license
  install -Dm644 "${srcdir}/LICENSE" "${pkgdir}/opt/${pkgname}/LICENSE"
  
  # Install desktop file
  install -Dm644 "squashfs-root/${_pkgname}.desktop" \
    "${pkgdir}/usr/share/applications/${_binaryname}.desktop"
  
  # Install icons
  install -dm755 "${pkgdir}/usr/share/"
  cp -a "${srcdir}/squashfs-root/usr/share/icons" "${pkgdir}/usr/share/"
  
  # Create executable symlink
  install -dm755 "${pkgdir}/usr/bin"
  ln -s "/opt/${pkgname}/${_pkgname}.AppImage" "${pkgdir}/usr/bin/${_binaryname}"
}


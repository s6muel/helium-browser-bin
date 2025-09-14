# Maintainer: Sam Sinclair <sam at playleft dot com>

_pkgname="helium"
pkgname="${_pkgname}-browser-bin"
_binaryname="helium-browser"
pkgver=0.4.5.1
pkgrel=1
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
sha256sums_x86_64=('10f09a3630b5a34d10be2eba0a970adcf4927e97ae1175b1a3cac1ca9d59d183'
                   '3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986')

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
  # install -Dm755 "${_appimage}" "${pkgdir}/opt/${pkgname}/${_pkgname}.AppImage"
  
  # Install license
  # install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
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
# Maintainer: Sam Sinclair (sam at playleft dot com)
#
# _pkgname="helium"
# pkgname="${_pkgname}-browser-bin"
# _desktopname="helium-browser"
# pkgver=0.4.5.1
# pkgrel=1
# pkgdesc="Private, fast, and honest web browser based on Chromium"
# arch=('x86_64')
# url="https://github.com/imputnet/helium-linux"
# license=('GPL3')
# options=(!strip)
# _appimage="${_pkgname}-${pkgver}-x86_64.AppImage"
#
# source_x86_64=(
#   "${_appimage}::https://github.com/imputnet/helium-linux/releases/download/${pkgver}/${_pkgname}-${pkgver}-x86_64.AppImage"
#   "https://raw.githubusercontent.com/imputnet/helium-linux/main/LICENSE"
# )
# noextract=("${_appimage}")
# sha256sums_x86_64=('10f09a3630b5a34d10be2eba0a970adcf4927e97ae1175b1a3cac1ca9d59d183'
#                    '3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986')
#
# prepare() {
#   chmod +x "${_appimage}"
#   ./"${_appimage}" --appimage-extract
# }
#
# build() {
#     # Adjust .desktop so it will work outside of AppImage container
#     sed -i -E "s|Exec=AppRun|Exec=env /usr/bin/${_desktopname}|"\
#         "squashfs-root/${_pkgname}.desktop"
#     # Fix permissions; .AppImage permissions are 700 for all directories
#     chmod -R a-x+rX squashfs-root/usr
# }
#
# package() {
#   # Install AppImage under /opt
#   install -Dm755 "${srcdir}/${_appimage}" "${pkgdir}/opt/${pkgname}/${_pkgname}.AppImage"
#   install -Dm644 "${srcdir}/LICENSE" "${pkgdir}/opt/${pkgname}/LICENSE"
#
#   # Desktop entry
#   install -Dm644 "${srcdir}/squashfs-root/${_pkgname}.desktop" \
# 	  "${pkgdir}/usr/share/applications/${_desktopname}.desktop"
#
#   # Icons from AppImage
#   install -dm755 "${pkgdir}/usr/share/"
#   cp -a "${srcdir}/squashfs-root/usr/share/icons" "${pkgdir}/usr/share/"
#
#   # Symlink executable
#   install -dm755 "${pkgdir}/usr/bin"
#   ln -s "/opt/${pkgname}/${_pkgname}.AppImage" "${pkgdir}/usr/bin/${_desktopname}"
#
#   # Symlink license
#   install -dm755 "${pkgdir}/usr/share/licenses/${pkgname}/"
#   ln -s "/opt/${pkgname}/LICENSE" "$pkgdir/usr/share/licenses/$pkgname"
# }
#

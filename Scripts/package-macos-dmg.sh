#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="${GLISSPAD_VERSION:-1.0.0}"
build_number="${GLISSPAD_BUILD_NUMBER:-1}"
dist_dir="${project_root}/dist"
staging_root="${project_root}/.build/dmg"
staging_dir="${staging_root}/GlissPad-${version}"
app_path="${staging_dir}/GlissPad.app"
bundle_root="${app_path}/Contents"
binary_path="${project_root}/.build/release/glisspad"
dmg_path="${dist_dir}/GlissPad-v${version}.dmg"

if [[ ! "${version}" =~ ^[0-9]+([.][0-9]+){2}$ ]]; then
  echo "GLISSPAD_VERSION must use semantic form like 1.0.0." >&2
  exit 64
fi

if [[ ! "${build_number}" =~ ^[0-9]+$ ]]; then
  echo "GLISSPAD_BUILD_NUMBER must be a positive integer." >&2
  exit 64
fi

cd "${project_root}"
swift build -c release

rm -rf "${staging_dir}"
mkdir -p "${bundle_root}/MacOS" "${bundle_root}/Resources" "${dist_dir}"

cp "${project_root}/Packaging/Info.plist" "${bundle_root}/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${version}" "${bundle_root}/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${build_number}" "${bundle_root}/Info.plist"

cp "${project_root}/Packaging/GlissPad.icns" "${bundle_root}/Resources/GlissPad.icns"
cp "${binary_path}" "${bundle_root}/MacOS/glisspad"
chmod 755 "${bundle_root}/MacOS/glisspad"
ln -s /Applications "${staging_dir}/Applications"

sign_identity="${GLISSPAD_CODESIGN_IDENTITY:-}"
if [ -z "${sign_identity}" ]; then
  sign_identity="$(security find-identity -v -p codesigning | awk -F '\"' '/Apple Development/ { print $2; exit }')"
fi
if [ -z "${sign_identity}" ]; then
  sign_identity="-"
fi

codesign --force --deep --sign "${sign_identity}" "${app_path}"
rm -f "${dmg_path}"
hdiutil create \
  -volname "GlissPad ${version}" \
  -srcfolder "${staging_dir}" \
  -ov \
  -format UDZO \
  "${dmg_path}"

echo "${dmg_path}"

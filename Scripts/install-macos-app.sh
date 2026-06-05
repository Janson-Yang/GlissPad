#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_path="/Applications/GlissPad.app"
bundle_root="${app_path}/Contents"
binary_path="${project_root}/.build/release/glisspad"
resource_bundle_path="${project_root}/.build/release/glisspad_GlissPad.bundle"
legacy_app_name="$(printf '%s%s' 'Tap' 'line')"
legacy_app_path="/Applications/${legacy_app_name}.app"

cd "${project_root}"
rm -rf "${resource_bundle_path}"
swift build -c release

mkdir -p "${bundle_root}/MacOS" "${bundle_root}/Resources"
cp "${project_root}/Packaging/Info.plist" "${bundle_root}/Info.plist"
cp "${project_root}/Packaging/GlissPad.icns" "${bundle_root}/Resources/GlissPad.icns"
cp "${binary_path}" "${bundle_root}/MacOS/glisspad"
chmod 755 "${bundle_root}/MacOS/glisspad"
if [ ! -d "${resource_bundle_path}" ]; then
  echo "Missing resource bundle: ${resource_bundle_path}" >&2
  exit 66
fi
rm -rf "${bundle_root}/Resources/glisspad_GlissPad.bundle"
cp -R "${resource_bundle_path}" "${bundle_root}/Resources/"

sign_identity="${GLISSPAD_CODESIGN_IDENTITY:-}"
if [ -z "${sign_identity}" ]; then
  sign_identity="$(security find-identity -v -p codesigning | awk -F '\"' '/Apple Development/ { print $2; exit }')"
fi
if [ -z "${sign_identity}" ]; then
  sign_identity="-"
fi

codesign --force --deep --sign "${sign_identity}" "${app_path}"
if [ -d "${legacy_app_path}" ]; then
  rm -rf "${legacy_app_path}"
fi
echo "${app_path}"

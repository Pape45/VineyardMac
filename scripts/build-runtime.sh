#!/bin/bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 SOURCE_DIRECTORY OUTPUT_DIRECTORY" >&2
    exit 64
fi

repository_root=$(cd "$(dirname "$0")/.." && pwd)
manifest="$repository_root/Runtime/RuntimeManifest.json"
source_directory=$(cd "$1" && pwd)
output_directory=$2
work_directory=$(mktemp -d)
trap 'rm -rf "$work_directory"' EXIT

sha256() {
    shasum -a 256 "$1" | awk '{print $1}'
}

source_file() {
    local source=$1
    printf '%s/%s\n' \
        "$source_directory" \
        "$(plutil -extract "sources.$source.fileName" raw "$manifest")"
}

require_hash() {
    local source=$1
    local file
    local expected
    file=$(source_file "$source")
    expected=$(plutil -extract "sources.$source.sha256" raw "$manifest")
    require_file_hash "$file" "$expected"
}

require_file_hash() {
    local file=$1
    local expected=$2
    local actual
    actual=$(sha256 "$file")
    if [[ "$actual" != "$expected" ]]; then
        echo "SHA-256 mismatch for $file" >&2
        echo "Expected: $expected" >&2
        echo "Actual:   $actual" >&2
        exit 65
    fi
}

for source in gcenxRuntime vulkanDriver dxvk moltenVK winetricks appleLicense; do
    require_hash "$source"
done

runtime="$work_directory/Libraries"
mkdir -p "$runtime"

gcenx="$work_directory/gcenx"
mkdir -p "$gcenx"
tar -xJf "$(source_file gcenxRuntime)" -C "$gcenx"
ditto \
    "$gcenx/Game Porting Toolkit.app/Contents/Resources/wine" \
    "$runtime/Wine"

vulkan_driver="$work_directory/vulkan-driver"
mkdir -p "$vulkan_driver"
tar -xzf "$(source_file vulkanDriver)" -C "$vulkan_driver"
for architecture in x86_64-unix x86_32on64-unix; do
    driver="$vulkan_driver/Libraries/Wine/lib/wine/$architecture/winemac.drv.so"
    hash_key=${architecture%%-*}
    require_file_hash \
        "$driver" \
        "$(plutil -extract "sources.vulkanDriver.${hash_key}SHA256" raw "$manifest")"
    cp -p "$driver" "$runtime/Wine/lib/wine/$architecture/winemac.drv.so"
done

mkdir -p "$runtime/DXVK"
tar -xzf "$(source_file dxvk)" --strip-components 1 -C "$runtime/DXVK"
rm -f "$runtime/DXVK/.DS_Store"

moltenvk="$work_directory/moltenvk"
mkdir -p "$moltenvk"
tar -xf "$(source_file moltenVK)" -C "$moltenvk"
cp -p \
    "$moltenvk/MoltenVK/MoltenVK/dynamic/dylib/macOS/libMoltenVK.dylib" \
    "$runtime/Wine/lib/"

winetricks="$work_directory/winetricks"
mkdir -p "$winetricks"
tar -xzf "$(source_file winetricks)" --strip-components 1 -C "$winetricks"
cp -p "$winetricks/src/winetricks" "$runtime/winetricks"
cp -p "$winetricks/files/verbs/all.txt" "$runtime/verbs.txt"
chmod +x "$runtime/winetricks"

mkdir -p "$runtime/Licenses/Apple Game Porting Toolkit"
cp -p \
    "$(source_file appleLicense)" \
    "$runtime/Licenses/Apple Game Porting Toolkit/License.pdf"
mkdir -p \
    "$runtime/Licenses/DXVK" \
    "$runtime/Licenses/MoltenVK" \
    "$runtime/Licenses/Wine" \
    "$runtime/Licenses/Winetricks"
cp -p "$repository_root/Runtime/Licenses/DXVK-LICENSE" "$runtime/Licenses/DXVK/LICENSE"
cp -p "$moltenvk/MoltenVK/LICENSE" "$runtime/Licenses/MoltenVK/"
cp -p "$repository_root/Runtime/Licenses/Wine-COPYING.LIB" "$runtime/Licenses/Wine/COPYING.LIB"
cp -p "$winetricks/COPYING" "$runtime/Licenses/Winetricks/"
cp -p "$manifest" "$runtime/RuntimeManifest.json"

runtime_version=$(plutil -extract runtimeVersion raw "$manifest")
minimum_macos=$(plutil -extract minimumMacOSVersion raw "$manifest")
version_core=${runtime_version%%-*}
pre_release=${runtime_version#*-}
IFS=. read -r version_major version_minor version_patch <<< "$version_core"
version_plist="$runtime/WhiskyWineVersion.plist"
plutil -create xml1 "$version_plist"
plutil -insert version -xml '<dict/>' "$version_plist"
plutil -insert version.major -integer "$version_major" "$version_plist"
plutil -insert version.minor -integer "$version_minor" "$version_plist"
plutil -insert version.patch -integer "$version_patch" "$version_plist"
plutil -insert version.preRelease -string "$pre_release" "$version_plist"
plutil -insert version.build -string 2 "$version_plist"

[[ -x "$runtime/Wine/bin/wine64" ]]
[[ -x "$runtime/Wine/bin/wineserver" ]]
"$runtime/Wine/bin/wine64" --version | grep 'wine-7.7' >/dev/null
d3dmetal="$runtime/Wine/lib/external/D3DMetal.framework/Versions/A/D3DMetal"
strings "$d3dmetal" | grep 'D3DMetal-3.0' >/dev/null
codesign --verify --strict "$runtime/Wine/lib/external/D3DMetal.framework"
gstreamer_info="$runtime/Wine/lib/GStreamer.framework/Versions/1.0/Resources/Info.plist"
[[ "$(plutil -extract CFBundleShortVersionString raw "$gstreamer_info")" == "1.28.1.1" ]]

mkdir -p "$output_directory"
archive="$output_directory/Libraries.tar.gz"
COPYFILE_DISABLE=1 tar -czf "$archive" -C "$work_directory" Libraries
archive_sha=$(sha256 "$archive")

cp -p "$manifest" "$output_directory/RuntimeManifest.json"
release_plist="$output_directory/WhiskyWineVersion.plist"
cp -p "$version_plist" "$release_plist"
plutil -insert archiveURL -string \
    "https://data.vineyardmac.app/Wine/archive/Libraries-$runtime_version.tar.gz" \
    "$release_plist"
plutil -insert archiveSHA256 -string "$archive_sha" "$release_plist"
plutil -insert minimumMacOSVersion -string "$minimum_macos" "$release_plist"

echo "Runtime $runtime_version built at $archive"
echo "SHA-256: $archive_sha"

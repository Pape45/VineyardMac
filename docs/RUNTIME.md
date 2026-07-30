# Runtime Maintenance

VineyardMac downloads its Wine runtime from `data.vineyardmac.app`. The runtime is built separately from the app because it contains Wine and third-party compatibility components, including Apple's redistributable Game Porting Toolkit libraries.

## Current Runtime

Runtime `4.0.0-beta.2` contains:

- Wine 7.7 and D3DMetal 3.0 from Gcenx Game Porting Toolkit 3.0-3;
- the VineyardMac Wine macOS driver from commit `32ff36f`, preserving Vulkan support for DXVK;
- DXVK-macOS 1.10.3-20230507-async;
- MoltenVK 1.4.2;
- GStreamer 1.28.1.1;
- Winetricks 20260125.

The complete machine-readable inventory and source hashes are in [`Runtime/RuntimeManifest.json`](../Runtime/RuntimeManifest.json).

## Building

Download the six source files listed in the manifest into one directory. Do not commit the source files or generated runtime archive. Then run:

```bash
scripts/build-runtime.sh \
  /path/to/source-files \
  /path/to/output
```

The script verifies every source hash, copies the Gcenx runtime without rebuilding Wine, restores the two VineyardMac Wine driver modules needed by DXVK, adds the pinned DXVK, MoltenVK, and Winetricks releases, preserves their licenses, and writes:

- `Libraries.tar.gz`;
- `WhiskyWineVersion.plist` with the archive URL and SHA-256;
- `RuntimeManifest.json`.

## Publishing

Archive every build under its versioned `Wine/archive/` key before updating the current download. Upload the current archive first and confirm its remote SHA-256, then upload `RuntimeManifest.json`. Upload `WhiskyWineVersion.plist` last because clients treat it as the release pointer.

The app verifies the archive SHA-256, its required files, the internal manifest, and the embedded version before replacing an installed runtime. Installation occurs in a staging directory and keeps the previous runtime until validation succeeds.

Game Porting Toolkit redistributables may only be distributed according to Apple's license. VineyardMac's runtime distribution is non-commercial and retains the license linked by the exact Gcenx release used.

## GPTK 4 Status

Apple's GPTK 4 readme recommends Gcenx as the pre-built Wine environment and describes replacing its evaluation libraries with the GPTK 4 beta 2 redistributables. That replacement currently fails the D3D11 and D3D12 smoke tests on the maintainer's macOS 27 beta system, while Gcenx 3.0-3 passes both. Do not publish a GPTK 4 runtime until the same smoke tests pass.

## Smoke Test

After extracting the generated archive and initializing a temporary Wine prefix, compile and run the DirectX smoke test:

```bash
x86_64-w64-mingw32-gcc -Wall -Wextra -Werror Runtime/SmokeTests/directx.c \
  -o directx.exe
WINEPREFIX=/path/to/test-prefix /path/to/Libraries/Wine/bin/wine64 directx.exe d3d11
WINEPREFIX=/path/to/test-prefix /path/to/Libraries/Wine/bin/wine64 directx.exe d3d12
```

A passing run creates both a D3D11 and D3D12 device. Use a disposable prefix; never run runtime smoke tests against a user's bottle.

Also verify the optional DXVK path after copying its DLLs into the disposable prefix:

```bash
cp /path/to/Libraries/DXVK/x64/{d3d9,d3d10core,d3d11,dxgi}.dll \
  /path/to/test-prefix/drive_c/windows/system32/
cp /path/to/Libraries/DXVK/x32/{d3d9,d3d10core,d3d11,dxgi}.dll \
  /path/to/test-prefix/drive_c/windows/syswow64/
WINEPREFIX=/path/to/test-prefix \
WINEDLLOVERRIDES='dxgi,d3d9,d3d10core,d3d11=n,b' \
DXVK_STATE_CACHE=0 \
  /path/to/Libraries/Wine/bin/wine64 directx.exe d3d11
```

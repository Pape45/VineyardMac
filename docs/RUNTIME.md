# Runtime Maintenance

VineyardMac downloads its Wine runtime from `data.vineyardmac.app`. The runtime is built separately from the app because it contains Wine and third-party compatibility components, including Apple's redistributable Game Porting Toolkit libraries.

## Staged Runtime

Runtime `4.0.0-beta.2` contains:

- Wine 7.7 and D3DMetal 3.0 from Gcenx Game Porting Toolkit 3.0-3;
- the VineyardMac Wine macOS driver from commit `32ff36f`, preserving Vulkan support for DXVK;
- DXVK-macOS 1.10.3-20230507-async;
- MoltenVK 1.4.2;
- GStreamer 1.28.1.1;
- Winetricks 20260125.

The complete machine-readable inventory and source hashes are in [`Runtime/RuntimeManifest.json`](../Runtime/RuntimeManifest.json).

The `4.0.0-beta.2` archive is stored at its immutable `Wine/archive/` URL. The public release pointer still targets the previous runtime and must not be advanced until PR #4 is merged and prepublication validation passes; the fresh setup test follows immediately after publishing the pointer.

## Building

Download the six source files listed in the manifest into one directory. Do not commit the source files or generated runtime archive. Then run:

```bash
scripts/build-runtime.sh \
  /path/to/source-files \
  /path/to/output
```

The script verifies every source hash, copies the Gcenx runtime without rebuilding Wine, restores the two VineyardMac Wine driver modules needed by DXVK, adds the pinned DXVK, MoltenVK, and Winetricks releases, preserves their licenses, and writes:

- `Libraries.tar.gz`, the local archive also uploaded to the mutable path used by older clients;
- `WhiskyWineVersion.plist` with the SHA-256 and immutable `Wine/archive/Libraries-<version>.tar.gz` URL;
- `RuntimeManifest.json`.

## Publishing

Before activation, verify that the generated plist version, immutable URL, and SHA-256 match the local archive. Extract that archive, validate its required files, embedded version, and manifest, then run the smoke tests below with a disposable prefix.

Keep the previous release plist and mutable archive available for rollback. Publish the validated `Libraries.tar.gz` bytes under the immutable `Wine/archive/Libraries-<version>.tar.gz` key and confirm the remote size and SHA-256. Upload the same bytes to mutable `Wine/Libraries.tar.gz` for older clients, then upload `RuntimeManifest.json`. Upload `WhiskyWineVersion.plist` last because current clients treat it as the release pointer.

Immediately after publishing the pointer, perform a fresh setup, create a bottle, and launch `winecfg` or the DirectX smoke executable. If that acceptance test fails, restore the previous `WhiskyWineVersion.plist` and `Wine/Libraries.tar.gz`, verify both remote objects, and repeat the fresh setup test. Keep the failed immutable archive unchanged for diagnosis; immutable keys are never overwritten during rollback.

The app verifies the archive SHA-256, its required files, the internal manifest, and the embedded version before replacing an installed runtime. Installation occurs in a staging directory and keeps the previous runtime until validation succeeds.

Game Porting Toolkit redistributables may only be distributed according to Apple's license. VineyardMac's runtime distribution is non-commercial and retains the license linked by the exact Gcenx release used.

## GPTK 4 Status

[Game Porting Toolkit 4](https://developer.apple.com/games/game-porting-toolkit) includes an updated evaluation environment. An experiment on macOS 27 beta and Xcode 27 beta replaced the Gcenx 3.0-3 evaluation libraries with GPTK 4 beta 2, but both D3D11 and D3D12 smoke tests failed.

A follow-up Wine source experiment used Gcenx commit `2e232b59da4612f2f131bd2f690d70d8fbdf9b87`. The patched PE `ntdll.dll` and `gdi32.dll` built, but mixing them with the existing native `ntdll.so` failed with a syscall count mismatch. Building the matching native half with LLVM 22 then failed on assembler labels inside CFI blocks. The maintainer recovery folder preserves the patch and logs needed to resume this work.

Apple's [`game-porting-toolkit-compiler`](https://github.com/apple/homebrew-apple/blob/main/Formula/game-porting-toolkit-compiler.rb) formula is still version 0.1 and builds the compiler from CrossOver 22.1.1 sources. It is not required to assemble or publish the staged runtime. Do not publish a GPTK 4 runtime until the DirectX smoke tests pass with a complete, internally matched Wine build.

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

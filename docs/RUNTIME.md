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

The `4.0.0-beta.2` archive is stored at its immutable `Wine/archive/` URL. It became the public runtime on 2026-08-11 after prepublication validation and an immediate fresh graphical setup test.

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

Treat the runtime being activated as the target version and the runtime referenced before any mutation as the previous public version. Before activation, verify that the target plist version, immutable URL, and SHA-256 match the local archive. Extract that archive, validate its required files, embedded version, and manifest, then run the smoke tests below with a disposable prefix.

Before mutating R2, stop the app and its Wine processes. Record whether the managed local `Libraries` runtime exists; if it does, move the whole directory to an explicit backup location so it can be moved back unchanged, and if it does not, record that absence. Never move, delete, or modify any bottle or bottle-list file during runtime activation.

Download and verify exact rollback copies of the previous public `Wine/WhiskyWineVersion.plist` and `Wine/Libraries.tar.gz`. Also preserve the exact previous state of `Wine/RuntimeManifest.json`: save and verify its bytes if it exists, or record and verify its absence if it returns 404. Do not begin publication until all three public states and the local runtime state are recoverable.

If the target immutable `Wine/archive/Libraries-<version>.tar.gz` key does not exist, upload the validated `Libraries.tar.gz` bytes once. If it already exists, only verify its size and SHA-256 against the validated archive. If either differs, stop and use a new target version and immutable key; never overwrite an existing immutable key. After verifying the immutable object, upload the same bytes to mutable `Wine/Libraries.tar.gz` for older clients and verify its public SHA-256, then upload and verify the target `RuntimeManifest.json`. Upload and verify `WhiskyWineVersion.plist` last because current clients treat it as the release pointer.

Wrangler's `r2 object put` command refuses files larger than 300 MiB even though R2 accepts larger objects. When the verified immutable object already exists in the same bucket, an ephemeral Worker with an R2 binding can stream the result of `get(immutableKey).body` into `put("Wine/Libraries.tar.gz", ...)`. Guard the copy with the expected source and destination size and ETag, never write the immutable key, stop the Worker after the single copy, and verify the mutable object's public SHA-256 before publishing anything else. This performs one R2 read and one write with no R2 egress charge, but account quotas must still be checked.

Immediately after publishing the pointer, perform a fresh setup, create only a disposable bottle, and launch `winecfg` or the DirectX smoke executable. Never use or modify an existing bottle.

If publication or acceptance fails after the first R2 mutation, restore the previous public version exactly: restore and verify its saved `WhiskyWineVersion.plist` first, restore and verify its saved mutable `Libraries.tar.gz`, then restore the root manifest to its exact previous state by uploading the saved bytes or removing it if it was previously absent and verifying that absence. Stop only the app and Wine processes associated with the test, quarantine any newly installed target runtime, and move the saved local runtime back unchanged; if the local runtime was previously absent, restore that absence. Do not touch bottles or bottle lists. Keep every versioned immutable key unchanged for diagnosis.

The app verifies the archive SHA-256, its required files, the internal manifest, and the embedded version before replacing an installed runtime. Installation occurs in a staging directory and keeps the previous runtime until validation succeeds.

Game Porting Toolkit redistributables may only be distributed according to Apple's license. VineyardMac's runtime distribution is non-commercial and retains the license linked by the exact Gcenx release used.

## Beta.2 Activation Record

The beta.2 activation published a mutable archive of `404974593` bytes with SHA-256 `86f9a7f6280b1648e5a7a640023a3a443870c882fdd214c062ce60b344004ef4`, a root manifest with SHA-256 `cc2bbe8061f5bb3176a14481bb0da3902c3300108ee9251b99d3a85178ef4c67`, and the complete `4.0.0-beta.2+2` plist. A fresh setup installed that version, reproduced the repository manifest, created a disposable bottle, and launched `winecfg`; the bottle and its processes were then removed.

For that historical beta.2 activation, the previous public version was beta.1. Its plist lacked the metadata required by the strict installer, so restoring beta.1 would have protected older clients only; strict app distribution and successful strict fresh-setup claims would have remained suspended until a fully validatable runtime was published under a new immutable key.

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

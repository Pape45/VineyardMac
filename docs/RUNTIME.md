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

Before mutating R2, stop the app and its Wine processes. Record whether the managed local `Libraries` runtime exists; if it does, move the whole directory to an explicit backup location so it can be moved back unchanged, and if it does not, record that absence. Never move, delete, or modify a pre-existing bottle or bottle-list entry. The later acceptance test may create and remove only its one explicitly tracked disposable bottle and matching new reference.

Download and verify exact rollback copies of the previous public `Wine/WhiskyWineVersion.plist` and `Wine/Libraries.tar.gz`. Also preserve the exact previous state of `Wine/RuntimeManifest.json`: save and verify its bytes if it exists, or record and verify its absence if it returns 404. Do not begin publication until all three public states and the local runtime state are recoverable.

If the target immutable `Wine/archive/Libraries-<version>.tar.gz` key does not exist, upload the validated `Libraries.tar.gz` bytes once. If it already exists, only verify its size and SHA-256 against the validated archive. If either differs, stop and use a new target version and immutable key; never overwrite an existing immutable key. After verifying the immutable object, upload the same bytes to mutable `Wine/Libraries.tar.gz` for older clients and verify its public SHA-256, then upload and verify the target `RuntimeManifest.json`. Upload and verify `WhiskyWineVersion.plist` last because current clients treat it as the release pointer.

Wrangler's `r2 object put` command refuses files larger than 300 MiB even though R2 accepts larger objects. When the verified immutable object already exists in the same bucket, an ephemeral Worker with an R2 binding can stream the result of `get(immutableKey).body` into `put("Wine/Libraries.tar.gz", ...)`. Guard the copy with the expected source and destination size and ETag, never write the immutable key, stop the Worker after the single copy, and verify the mutable object's public SHA-256 before publishing anything else. This performs one R2 read and one write with no R2 egress charge, but account quotas must still be checked.

Immediately after publishing the pointer, perform a fresh setup, create one explicitly tracked disposable bottle, and launch `winecfg` or the DirectX smoke executable. After validation, stop only its processes, delete only that bottle directory, and remove only its matching reference. Never use or modify a pre-existing bottle or reference.

If publication or acceptance fails after the first R2 mutation, restore the previous public version exactly: restore and verify its saved mutable `Libraries.tar.gz`, restore the root manifest to its exact previous state by uploading the saved bytes or removing it if it was previously absent and verify that state, then restore and verify its saved `WhiskyWineVersion.plist` last as the release pointer. Stop only the app and Wine processes associated with the test, remove only the explicitly tracked disposable bottle and its matching reference if created, quarantine any newly installed target runtime, and move the saved local runtime back unchanged; if the local runtime was previously absent, restore that absence. Do not touch any pre-existing bottle or reference. Keep every versioned immutable key unchanged for diagnosis.

The app verifies the archive SHA-256, its required files, the internal manifest, and the embedded version before replacing an installed runtime. Installation occurs in a staging directory and keeps the previous runtime until validation succeeds.

Game Porting Toolkit redistributables may only be distributed according to Apple's license. VineyardMac's runtime distribution is non-commercial and retains the license linked by the exact Gcenx release used.

## Beta.2 Activation Record

The beta.2 activation published a mutable archive of `404974593` bytes with SHA-256 `86f9a7f6280b1648e5a7a640023a3a443870c882fdd214c062ce60b344004ef4`, a root manifest with SHA-256 `cc2bbe8061f5bb3176a14481bb0da3902c3300108ee9251b99d3a85178ef4c67`, and the complete `4.0.0-beta.2+2` plist. A fresh setup installed that version, reproduced the repository manifest, created a disposable bottle, and launched `winecfg`; the bottle and its processes were then removed.

For that historical beta.2 activation, the previous public version was beta.1. Its plist lacked the metadata required by the strict installer, so restoring beta.1 would have protected older clients only; strict app distribution and successful strict fresh-setup claims would have remained suspended until a fully validatable runtime was published under a new immutable key.

## GPTK 4 Private Candidate

[Game Porting Toolkit 4](https://developer.apple.com/games/game-porting-toolkit) beta 2 now has a coherent Wine 7.7 build and a private strict-installer candidate. `VineyardMac-Wine` packaging commit `ff85d649d8b722f709f9b134b2d1c4eba85281cd` produced `4.0.0-beta.3+3` in CI run [`31708933259`](https://github.com/Pape45/VineyardMac-Wine/actions/runs/31708933259). Its external plist records minimum macOS `15.0`, archive SHA-256 `066edfdf3024eb0c1fc1cbaa8d9de37e5c9e216d723ca6e787bb4adea6e63764`, and the reserved immutable URL `Wine/archive/Libraries-4.0.0-beta.3.tar.gz`.

The archive contains 4,612 regular files. The previous smoke artifact contained 4,604; strict compatibility adds exactly the two missing DXVK `d3d9.dll` files, `RuntimeManifest.json`, three Apple notices, and two Wine license files without removing existing payload files. All checksum entries, 18 installer-required paths, embedded version, manifest, confined archive paths, executable bits, and notice hashes passed validation.

The candidate rebuild changed 118 of 141 comparable graphics binaries, so D3D11 and D3D12 were repeated in separate disposable prefixes. Both exited `0`: D3D11 reported feature level `0xb000`, and D3D12 created its device; neither log contained a page fault or syscall count mismatch. D3DMetal remains `4.0b2`.

This is not an activation record. The CI R2 step was skipped, the reserved beta.3 key still returned HTTP 404 after CI, and no VineyardMac installer or fresh setup was run. Public runtime `4.0.0-beta.2` and [`Runtime/RuntimeManifest.json`](../Runtime/RuntimeManifest.json) remain unchanged. Public redistribution must remain non-commercial and retain Apple's notices.

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

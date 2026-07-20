# Upstream References

Exact pinned versions/commits this build depends on. This repo does not re-host any
upstream source tarball — clone/download from the links below to reproduce the exact
inputs `build_ffmpeg.sh` consumes.

## Build harness

- **Javernaut/ffmpeg-android-maker**
  Commit: `dd72b161ae5c759fd25a5cab971a3ff710f0bdba` (tag `v2.12-50-gdd72b16`)
  https://github.com/Javernaut/ffmpeg-android-maker/tree/dd72b161ae5c759fd25a5cab971a3ff710f0bdba
  License: MIT (harness itself; each library it builds carries its own license, see below)
  PocketScript applies `patches/ffmpeg-android-maker.patch` (in this repo) on top of
  this exact commit before building — see `HOW_TO_REBUILD.md`.

## FFmpeg

- **FFmpeg** version 8.1.2
  https://github.com/FFmpeg/FFmpeg (release tag `n8.1.2`)
  License: LGPL v2.1 or later (this build's configure flags disable every GPL/nonfree
  component — see `build_ffmpeg.sh`'s `ffmpeg-android-maker.sh` invocation, which
  passes no `--enable-gpl`/`--enable-nonfree`/`--enable-version3` flag).
  Upstream license text: `COPYING.LGPLv2.1` in the FFmpeg source tree.

## External libraries (built via the patch's new `scripts/libass`, `scripts/libharfbuzz`,
## and patched `scripts/libfribidi` build scripts inside ffmpeg-android-maker)

- **libass** version 0.17.5
  https://github.com/libass/libass/releases/tag/0.17.5
  License: ISC License (see upstream `COPYING` file). Built shared, with FreeType and
  HarfBuzz statically merged in (see `patches/ffmpeg-android-maker.patch`'s
  `scripts/libass/build.sh`).

- **HarfBuzz** version 14.2.1
  https://github.com/harfbuzz/harfbuzz/releases/tag/14.2.1
  License: MIT License (see upstream `COPYING` file). Built static, merged into
  `libass.so` only (permitted — MIT is permissive).

- **FriBidi** — version pinned by the unpatched upstream `ffmpeg-android-maker`
  harness's own `scripts/libfribidi/download.sh` at commit
  `dd72b161ae5c759fd25a5cab971a3ff710f0bdba` (see that file directly in the harness
  commit above for FriBidi's exact pinned version string). Only the *build* flags are
  patched by `patches/ffmpeg-android-maker.patch` (static→shared); the version/source
  URL is untouched from upstream.
  https://github.com/fribidi/fribidi
  License: LGPL v2.1 or later (see upstream `COPYING` file). Built
  `--enable-shared`/`--disable-static` (patched — see above) so it ships as its own
  `.so`, never statically merged into another binary.

- **FreeType** — version pinned by the unpatched upstream `ffmpeg-android-maker`
  harness's own `scripts/libfreetype/download.sh` at the same pinned commit above
  (freetype's download/build scripts are entirely unpatched by
  `patches/ffmpeg-android-maker.patch` — only libass's `configure` flags request
  `--enable-libfreetype` to link against it).
  https://github.com/freetype/freetype
  License: FreeType License (FTL). See upstream `docs/FTL.TXT`.

## NDK

- Android NDK r28c (`28.2.13676358`), as pinned in `build_ffmpeg.sh`.

## Android API level

- `minSdkVersion` / build target: API 29, as pinned in `build_ffmpeg.sh`.

# How to rebuild these libraries from scratch

This reproduces exactly what PocketScript ships in `nativemedia/prebuilt/{abi}/`
(which is gitignored in the main app repo — this source offer is what makes that
directory reproducible, per LGPL §6).

## Prerequisites

A POSIX build environment: native Linux, macOS, or WSL2 on Windows. Required host
tools: `make`, `pkg-config`, `nasm`, `yasm`, `unzip`, `curl`, `git`, `python3`,
`meson`, `ninja`.

On Ubuntu/WSL2:

```
sudo apt install -y build-essential pkg-config nasm yasm unzip ninja-build meson
```

## Steps

1. Clone the pinned upstream build harness at the exact commit referenced in
   `UPSTREAM_REFS.md`:

   ```
   git clone https://github.com/Javernaut/ffmpeg-android-maker.git
   cd ffmpeg-android-maker
   git checkout dd72b161ae5c759fd25a5cab971a3ff710f0bdba
   ```

2. Apply this repo's patch on top of that exact commit:

   ```
   git apply --no-index /path/to/pocketscript-source-offer/patches/ffmpeg-android-maker.patch
   ```

3. Run this repo's `build_ffmpeg.sh`, pointed at your checked-out+patched copy. In
   PocketScript's own app repo, this script expects to be run from
   `scripts/build_ffmpeg.sh` with the patched harness present at
   `third_party/ffmpeg-android-maker` relative to the repo root, and copies output
   into `nativemedia/prebuilt/{abi}/` relative to the repo root. To run it
   standalone against a manually-cloned+patched harness instead of that directory
   layout, set `REPO_ROOT`-relative paths accordingly, or simply place your patched
   `ffmpeg-android-maker` checkout at `third_party/ffmpeg-android-maker` under a
   directory that also has `scripts/build_ffmpeg.sh` and a `nativemedia/prebuilt/`
   destination, matching the layout `build_ffmpeg.sh`'s own header comment expects.

   The script itself (`build_ffmpeg.sh`, verbatim in this repo) downloads the pinned
   Android NDK r28c automatically, builds for `arm64-v8a` and `x86_64` by default
   (override via the `POCKETSCRIPT_FFMPEG_ABIS` environment variable), and produces
   `.so` + header outputs.

4. Output lands in `nativemedia/prebuilt/{abi}/*.so` (plus `include/` headers) —
   these are the exact files PocketScript's `:nativemedia` Android library module
   packages into the app via `jniLibs.srcDirs`.

## Notes on build flags (for LGPL audit purposes)

`build_ffmpeg.sh` invokes `ffmpeg-android-maker.sh` with exactly these feature flags:

```
--enable-libfreetype --enable-libharfbuzz --enable-libfribidi --enable-libass
```

No `--enable-gpl`, `--enable-nonfree`, `--enable-version3`, `--enable-libx264`, or
`--enable-libfdk-aac` flag is ever passed — this is the entire LGPL-only compliance
posture for the FFmpeg side of the build, and it is fully visible in this one command
in `build_ffmpeg.sh`. The patch additionally enables `--enable-jni --enable-mediacodec`
inside FFmpeg's own `scripts/ffmpeg/build.sh` (see `patches/ffmpeg-android-maker.patch`)
for hardware `h264_mediacodec` encode support used by PocketScript's burn-in export
feature — this is an FFmpeg core configure flag, not a GPL/nonfree component.

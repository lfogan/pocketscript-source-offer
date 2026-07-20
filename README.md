# PocketScript - LGPL Source Offer

This repository is the LGPL §6 "written offer" for **PocketScript** (Android app,
published by Quiet Reach Ltd, UK). PocketScript's main application source is
proprietary and closed; this repository exists solely to satisfy the source-availability
obligations of the LGPL-licensed components PocketScript links against, as required by
LGPL v2.1 §6.

It is **not** a mirror of the whole app. It contains only:

- The exact build script PocketScript uses to produce its FFmpeg + libass/freetype/
  harfbuzz/fribidi native library stack for Android (`build_ffmpeg.sh`).
- The exact patch PocketScript applies on top of the pinned upstream
  `ffmpeg-android-maker` build-harness commit (`patches/ffmpeg-android-maker.patch`).
- Pointers to every upstream project, exact pinned version/commit, and its own license
  (`UPSTREAM_REFS.md`) - this repo does not re-host upstream source tarballs; it points
  at the exact upstream commit/tag so anyone can reproduce byte-identical inputs.
- Rebuild instructions (`HOW_TO_REBUILD.md`).

## Which PocketScript component is this for?

PocketScript's native media pipeline builds a custom FFmpeg 8.1.2 for Android via the
[Javernaut/ffmpeg-android-maker](https://github.com/Javernaut/ffmpeg-android-maker)
build harness, patched to add libass (subtitle burn-in), harfbuzz (text shaping), and
a shared (not statically merged) build of fribidi (bidirectional text). The output is
five dynamically-linked `.so` files bundled into the PocketScript Android app:
`libavcodec.so`, `libavformat.so`, `libavutil.so`, `libavfilter.so`, `libswscale.so`,
`libswresample.so`, `libass.so`, and `libfribidi.so` (freetype and harfbuzz are
statically merged into `libass.so`; see the license notes below for why that's
permitted for those two but not for fribidi).

## License posture (why this repo exists)

PocketScript's FFmpeg build is configured **LGPL-only**: no `--enable-gpl`, no
`--enable-nonfree`, no `--enable-version3`, and no GPL-licensed external library
(e.g. libx264, fdk-aac) is ever enabled. Every LGPL-licensed component ships as its
own dynamically-linked `.so`, loaded via `System.loadLibrary()` from the app -
PocketScript never statically links LGPL object code into an app-owned binary.

- **FFmpeg** (`libavcodec`/`libavformat`/`libavutil`/`libavfilter`/`libswscale`/
  `libswresample`) — LGPL v2.1 or later, built with no GPL/nonfree components.
- **FriBidi** (`libfribidi.so`) — LGPL v2.1 or later. Patched (see
  `patches/ffmpeg-android-maker.patch`) to build `--enable-shared`/`--disable-static`
  instead of the upstream build harness's static-only default, specifically so it
  ships as its own separate `.so` rather than being statically absorbed into another
  binary, per LGPL §6.
- **libass** (`libass.so`) - ISC License (permissive). Statically merged with
  FreeType and HarfBuzz into one `.so`, which the ISC/FTL/MIT licenses of those three
  components permit.
- **FreeType** - used under the FreeType License (FTL). Its mandatory credit sentence
  ("Portions of this software are copyright © 2025 The FreeType Project
  (www.freetype.org). All rights reserved.") appears in the PocketScript app's Legal
  screen (year per FTL.TXT's own instruction: the release year of the FreeType
  version actually shipped - 2.14.3, tagged 2025).
- **HarfBuzz** - MIT License (permissive).

The full LGPL v2.1 license text is carried in this repo as `LGPL-2.1.txt` (verbatim
`COPYING.LGPLv2.1` from FFmpeg `n8.1.2`; FriBidi's `COPYING` is the same LGPL v2.1
text), so the offer and the license it references travel together.

See `UPSTREAM_REFS.md` for the exact pinned versions/commits and each project's own
license file location, and `HOW_TO_REBUILD.md` for how to reproduce the build from
these two files plus the pinned upstream commit.

## Contact

Questions about this source offer: hello@thequietreach.com

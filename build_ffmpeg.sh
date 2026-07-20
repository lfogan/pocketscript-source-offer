#!/usr/bin/env bash
# Builds the custom LGPL-only FFmpeg + libass/freetype/harfbuzz/fribidi stack for
# Android, via the third_party/ffmpeg-android-maker submodule, and copies the
# result into nativemedia/prebuilt/{abi}/ (gitignored — this script is what makes
# it reproducible; this repo itself is the LGPL §6 "source offer" requirement).
#
# Run this from a Linux shell: native Linux, macOS, or WSL2 on Windows (this repo
# was built and verified under WSL2 Ubuntu). Requires: make, pkg-config, nasm,
# yasm, unzip, curl, git, python3, meson, ninja.
#
# The actual compilation happens in a native-filesystem cache directory, NOT in
# this repo's checkout — when run under WSL2, building directly against a
# /mnt/c-mounted path is dramatically slower (thousands of small file ops over
# the 9p/DrvFs bridge) than a real Linux filesystem. Only the final .so/.h
# outputs are copied back into the repo.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="${POCKETSCRIPT_BUILD_CACHE:-$HOME/.pocketscript-build-cache}"
NDK_VERSION="28.2.13676358"
NDK_VERSION_TAG="r28c"
NDK_DIR="${CACHE_DIR}/android-ndk-${NDK_VERSION_TAG}"
WORK_DIR="${CACHE_DIR}/ffmpeg-android-maker-build"
TARGET_ABIS="${POCKETSCRIPT_FFMPEG_ABIS:-arm64-v8a,x86_64}"
ANDROID_API_LEVEL=29

mkdir -p "${CACHE_DIR}"

echo "== Checking required host tools =="
for tool in make pkg-config nasm yasm unzip curl git python3 meson ninja; do
  command -v "${tool}" >/dev/null 2>&1 || {
    echo "Missing required tool: ${tool}" >&2
    echo "On Ubuntu/WSL2: sudo apt install -y build-essential pkg-config nasm yasm unzip ninja-build meson" >&2
    exit 1
  }
done

echo "== Ensuring Linux NDK ${NDK_VERSION_TAG} at ${NDK_DIR} =="
if [ ! -d "${NDK_DIR}" ]; then
  curl -L -o "${CACHE_DIR}/ndk.zip" \
    "https://dl.google.com/android/repository/android-ndk-${NDK_VERSION_TAG}-linux.zip"
  unzip -q "${CACHE_DIR}/ndk.zip" -d "${CACHE_DIR}"
  rm "${CACHE_DIR}/ndk.zip"
fi
export ANDROID_NDK_HOME="${NDK_DIR}"
export ANDROID_SDK_HOME="${REPO_ROOT}"  # only presence-checked by the tool, never read

echo "== Preparing native-filesystem build workspace at ${WORK_DIR} =="
rm -rf "${WORK_DIR}"
cp -r "${REPO_ROOT}/third_party/ffmpeg-android-maker" "${WORK_DIR}"
# The copy carries over the submodule's .git file (a relative gitdir pointer that's
# broken once moved) — strip it so this is just a plain directory tree.
rm -rf "${WORK_DIR}/.git"

echo "== Applying PocketScript patch (libass/harfbuzz support, shared fribidi, jni/mediacodec) =="
cd "${WORK_DIR}"
git apply --no-index "${REPO_ROOT}/scripts/patches/ffmpeg-android-maker.patch"

echo "== Building FFmpeg for ${TARGET_ABIS} (this takes a while) =="
./ffmpeg-android-maker.sh \
  --target-abis="${TARGET_ABIS}" \
  --android-api-level="${ANDROID_API_LEVEL}" \
  --enable-libfreetype \
  --enable-libharfbuzz \
  --enable-libfribidi \
  --enable-libass

echo "== Copying prebuilt libraries into nativemedia/prebuilt/ =="
# .so files go directly under prebuilt/{abi}/ (not prebuilt/{abi}/lib/) to match
# AGP's jniLibs.srcDirs convention, which scans <srcDir>/<abi>/*.so directly.
# Headers live alongside in an include/ subdir — harmless to jniLibs, used only
# by our own CMake include_directories() for ff_extract.c/ff_burnin.c.
IFS=',' read -ra ABIS <<<"${TARGET_ABIS}"
for abi in "${ABIS[@]}"; do
  DEST="${REPO_ROOT}/nativemedia/prebuilt/${abi}"
  mkdir -p "${DEST}/include"
  cp "${WORK_DIR}/output/lib/${abi}"/*.so "${DEST}/"
  cp -r "${WORK_DIR}/output/include/${abi}"/* "${DEST}/include/"
  echo "  ${abi}: $(ls "${DEST}"/*.so | wc -l) .so files"
done

echo "== Done. Prebuilt libraries are in nativemedia/prebuilt/{abi}/ (gitignored) =="

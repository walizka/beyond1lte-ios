#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
xnu_path="${XNU_PATH:-$repo_root/xnu-ios15}"
build_root="${BUILD_DIR:-$repo_root/out/xnu-ios15}"
: "${KDKROOT:?Set KDKROOT to the installed kernel support kit}"
: "${B2L_DEPSROOT:?Set B2L_DEPSROOT to the isolated dependency root}"
export B2L_DEPSROOT

[[ "$(git -C "$xnu_path" rev-parse HEAD)" == 27b03b360a988dfd3dfdf34262bb0042026747cc ]] || {
	echo 'Unexpected iOS 15 XNU source revision.' >&2; exit 1;
}
[[ -f "$xnu_path/pexpert/pexpert/arm64/B2L.h" ]] || {
	echo 'Prepare the iOS 15 B2L patch and overlay before building.' >&2; exit 1;
}
python3 "$repo_root/scripts/stage-libpthread-ios15.py" "$xnu_path"
python3 "$repo_root/scripts/stage-bearssl-ios15.py" "$xnu_path"

cd "$xnu_path"
exec make SDKROOT=macosx KDKROOT="$KDKROOT" \
	TARGET_CONFIGS='DEVELOPMENT ARM64 B2L' \
	PLATFORM=iPhoneOS PLATFORM_FOR_CONFIG=iPhoneOS SDKVERSION=15.6 BTI_BUILD=0 \
	RC_DARWIN_KERNEL_VERSION=21.6.0 BUILD_LTO=0 BUILD_WERROR=0 \
	MEMORY_SIZE="${BUILD_MEMORY_BYTES:-8589934592}" \
	SYSCTL_HW_PHYSICALCPU="${BUILD_JOBS:-2}" SYSCTL_HW_LOGICALCPU="${BUILD_JOBS:-2}" \
	KERNEL_BUILDS_IN_PARALLEL=1 MAKEJOBS="-j${BUILD_JOBS:-2}" \
	OBJROOT="$build_root/obj" SYMROOT="$build_root/sym" DSTROOT="$build_root/dst" \
	build "$@"

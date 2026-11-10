#!/usr/bin/env bash
# Prepare the first Beyond1LTE CPU boot target against the iOS 15.6 XNU source.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
xnu_path="${1:-${XNU_PATH:-$repo_root/xnu-ios15}}"
expected=27b03b360a988dfd3dfdf34262bb0042026747cc

[[ "$(git -C "$xnu_path" rev-parse HEAD)" == "$expected" ]] || {
	echo "iOS 15 XNU must be at $expected" >&2
	exit 1
}

patch="$repo_root/patches/ios15/0001-b2l-xnu-8020-cpu.patch"
git -C "$xnu_path" apply --check "$patch"
git -C "$xnu_path" apply "$patch"

while IFS= read -r -d '' source_file; do
	relative="${source_file#"$repo_root/xnu-overlay/"}"
	destination="$xnu_path/$relative"
	if [[ -f "$destination" ]] && ! cmp -s "$source_file" "$destination"; then
		echo "Refusing to replace a different local overlay file: $destination" >&2
		exit 1
	fi
done < <(find "$repo_root/xnu-overlay" -type f -print0)
cp -a "$repo_root/xnu-overlay/." "$xnu_path/"

cat > "$xnu_path/bsd/kern/b2l_userspace_payload.h" <<'EOF'
/* Compile-only bootstrap: userspace payload is staged separately. */
static const unsigned char b2l_apps_executable[] = { 0 };
static const unsigned char b2l_apps_job[] = { 0 };
static const unsigned char b2l_apps_launch_cache[] = { 0 };
EOF

for source_file in "$repo_root/common/smp/"*; do
	destination="$xnu_path/iokit/Kernel/arm/$(basename "$source_file")"
	if [[ -f "$destination" ]] && ! cmp -s "$source_file" "$destination"; then
		echo "Refusing different generated SMP header: $destination" >&2
		exit 1
	fi
	cp "$source_file" "$destination"
done

echo "Prepared iOS 15.6 XNU CPU target: $xnu_path"

#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
xnu_path="${1:-$repo_root/xnu-ios15}"
xnu_sha=27b03b360a988dfd3dfdf34262bb0042026747cc

if [[ ! -d "$xnu_path/.git" ]]; then
	git clone --filter=blob:none --no-checkout https://github.com/apple-oss-distributions/xnu.git "$xnu_path"
fi

git -C "$xnu_path" fetch --depth 1 origin "$xnu_sha"
git -C "$xnu_path" checkout --detach "$xnu_sha"
actual="$(git -C "$xnu_path" rev-parse HEAD)"
[[ "$actual" == "$xnu_sha" ]] || { echo "Unexpected iOS 15 XNU revision: $actual" >&2; exit 1; }
echo "iOS 15 XNU source: $xnu_path @ $actual"

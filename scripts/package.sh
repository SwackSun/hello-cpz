#!/usr/bin/env bash
# Build an IPK for the hello example using GNU tar, gzip and ar.
set -euo pipefail
export LC_ALL=C
cd -- "$(dirname -- "$0")/.."
version=${1-$(<VERSION)}
if [[ $# -gt 1 || ! $version =~ ^[0-9][A-Za-z0-9.+~-]{0,63}$ ]]; then
    echo 'Usage: scripts/package.sh [VERSION] (defaults to the VERSION file)' >&2
    exit 2
fi
root=$(pwd -P)
stage=${HELLO_CPZ_STAGE:-"$root/out/device"}
binary="$stage/usr/bin/hello-cpz"
if [[ ! -x "$binary" || ! -f "$binary" ]]; then
    echo 'Build the example first with ./scripts/build.sh' >&2
    exit 1
fi
description=$(cat description.txt)
if [[ ! $description =~ ^[[:print:]]{1,49}$ ]]; then
    echo 'Expected a one-line English description of 1 to 49 characters.' >&2
    exit 1
fi

dist=${HELLO_CPZ_DIST:-"$root/dist"}
mkdir -p "$dist"
work=$(mktemp -d "$dist/.hello-cpz.XXXXXXXX")
trap 'rm -r -- "$work"' EXIT
cd "$work"
umask 022
install -Dm755 "$binary" data/usr/bin/hello-cpz
install -Dm644 "$stage/usr/share/doc/hello-cpz/README.md" data/usr/share/doc/hello-cpz/README.md
install -Dm644 "$stage/usr/share/licenses/hello-cpz/LICENSE" data/usr/share/licenses/hello-cpz/LICENSE
mkdir -p data/root/app control
ln -s ../../usr/bin/hello-cpz data/root/app/hello-cpz
cat > control/control <<META
Package: hello-cpz
Version: $version
Architecture: aarch64
Section: app
Description: $description
META
printf '2.0\n' > debian-binary
tar_args=(--format=gnu --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner)
tar "${tar_args[@]}" -C control -cf - ./control | gzip -n > control.tar.gz
tar "${tar_args[@]}" -C data -cf - ./usr ./root/app/hello-cpz | gzip -n > data.tar.gz
ar crD package.ipk debian-binary control.tar.gz data.tar.gz
ipk="$dist/hello-cpz_${version}_aarch64.ipk"
if ! ln -- package.ipk "$ipk" 2>/dev/null && ! cmp -s package.ipk "$ipk"; then
    echo 'Could not write the IPK. Use a new version for changed contents.' >&2
    exit 1
fi
printf '%s\n' "$ipk"

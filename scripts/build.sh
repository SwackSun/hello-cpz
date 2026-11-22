#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
export CM0_BUILDROOT_OUTPUT=${CM0_BUILDROOT_OUTPUT:-"$PWD/sdk-work/output"}
toolchain="$CM0_BUILDROOT_OUTPUT/host/share/buildroot/toolchainfile.cmake"
if [[ $CM0_BUILDROOT_OUTPUT != /* || ! -f $toolchain ]]; then
    echo 'Run scripts/install-dev-env.sh --ubuntu 26.04 or set CM0_BUILDROOT_OUTPUT to a complete SDK.' >&2
    exit 1
fi
mkdir -p out
exec 9>out/.build.lock
flock 9
cmake="$CM0_BUILDROOT_OUTPUT/host/bin/cmake"
if [[ ! -x $cmake ]]; then cmake=cmake; fi
"$cmake" --fresh --preset device -B out/build
"$cmake" --build out/build --parallel
DESTDIR="$PWD/out/device" "$cmake" --install out/build --component hello-cpz

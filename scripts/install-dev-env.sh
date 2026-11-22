#!/usr/bin/env bash
set -euo pipefail
usage() {
    echo 'Usage: scripts/install-dev-env.sh --ubuntu VERSION [--check]'
    echo 'Omit --ubuntu in a terminal to choose a version (default: 26.04).'
}

ubuntu_version=
check_only=false
while (( $# )); do
    case "$1" in
        --ubuntu)
            if [[ -n $ubuntu_version || -z ${2:-} || $2 == -* ]]; then
                usage >&2
                exit 2
            fi
            ubuntu_version=$2
            shift 2 ;;
        --check) check_only=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
if [[ -z $ubuntu_version ]]; then
    if [[ ! -t 0 ]]; then
        echo 'Specify --ubuntu 26.04 for non-interactive setup.' >&2
        exit 2
    fi
    read -r -p 'Ubuntu version [26.04]: ' ubuntu_version || exit 2
    ubuntu_version=${ubuntu_version:-26.04}
fi
if [[ $ubuntu_version != 26.04 ]]; then
    echo "Unsupported Ubuntu version: $ubuntu_version (supported: 26.04)." >&2
    exit 2
fi
. /etc/os-release
if [[ $ID != ubuntu || $VERSION_ID != "$ubuntu_version" ]]; then
    echo "This setup requires Ubuntu $ubuntu_version; detected $PRETTY_NAME." >&2
    exit 1
fi

cd -- "$(dirname -- "$0")/.."
work="$PWD/sdk-work"
output=${CM0_BUILDROOT_OUTPUT:-"$work/output"}
toolchain="$output/host/share/buildroot/toolchainfile.cmake"
if [[ -n ${CM0_BUILDROOT_OUTPUT:-} && ( $output != /* || ! -f $toolchain ) ]]; then
    echo 'CM0_BUILDROOT_OUTPUT must point to an existing Buildroot SDK (absolute path).' >&2
    exit 1
fi

packages=(build-essential util-linux binutils bison flex bc cpio rsync file unzip wget curl
          patch perl python3 git tar gzip xz-utils bzip2 ca-certificates libncurses-dev openssh-client)
if [[ ! -x $output/host/bin/cmake ]]; then packages+=(cmake); fi
missing=()
for package in "${packages[@]}"; do
    if [[ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true) != 'install ok installed' ]]; then
        missing+=("$package")
    fi
done
if "$check_only"; then
    if (( ${#missing[@]} )); then
        printf 'Missing: %s\n' "${missing[*]}" >&2
        exit 1
    fi
    echo 'Ubuntu host dependencies are ready.'
    exit 0
fi
if (( ${#missing[@]} )); then
    apt=(apt-get)
    if (( EUID != 0 )); then apt=(sudo apt-get); fi
    "${apt[@]}" update
    "${apt[@]}" install -y "${missing[@]}"
fi

if [[ -n ${CM0_BUILDROOT_OUTPUT:-} ]]; then
    printf 'Using existing Buildroot SDK: %s\n' "$output"
    exit 0
fi
if [[ $work == *[[:space:]]* ]]; then
    echo 'Buildroot requires a project path without whitespace.' >&2
    exit 1
fi

revision=8b238854d909c9cce32ef9671d968b03e323b55d
digest=2d5fe5fc0a979594fc3004c8d978219476340b684b1ca7dc9ca0ac0b312331e3
archive="$work/buildroot-$revision.tar.gz"
source_dir="$work/buildroot-$revision"
mkdir -p "$work"
exec 9>"$work/.setup.lock"
flock 9
scratch=$(mktemp -d "$work/.setup.XXXXXXXX")
trap 'rm -r -- "$scratch"' EXIT

verify_archive() {
    printf '%s  %s\n' "$digest" "$1" | sha256sum --check --status
}
if [[ ! -f $archive ]] || ! verify_archive "$archive"; then
    curl --fail --location --retry 3 --output "$scratch/buildroot.tar.gz" \
        "https://codeload.github.com/buildroot/buildroot/tar.gz/$revision"
    if ! verify_archive "$scratch/buildroot.tar.gz"; then
        echo 'Buildroot source checksum mismatch.' >&2
        exit 1
    fi
    mv -- "$scratch/buildroot.tar.gz" "$archive"
fi
if [[ ! -d $source_dir ]]; then
    tar -xzf "$archive" -C "$scratch"
    mv -T -- "$scratch/buildroot-$revision" "$source_dir"
fi
make -C "$source_dir" O="$output" BR2_DEFCONFIG="$PWD/scripts/hello_defconfig" defconfig
make -C "$output" toolchain
test -f "$toolchain"
printf 'Buildroot SDK ready at %s. Run ./scripts/build.sh next.\n' "$output"

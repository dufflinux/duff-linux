#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DUFF_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
WORKSPACE_DIR=${WORKSPACE_DIR:-$(dirname -- "$DUFF_DIR")}
VOID_PACKAGES_DIR=${VOID_PACKAGES_DIR:-"$WORKSPACE_DIR/void-packages"}
MAIN_REPO="$VOID_PACKAGES_DIR/hostdir/binpkgs"
NONFREE_REPO="$MAIN_REPO/nonfree"

usage() {
    cat <<EOF
Usage: $(basename "$0") --gpu amd|nvidia --kernel 6.19|7.0 [-- extra d77 args]

Environment variables:
  WORKSPACE_DIR       Parent directory containing the repos
  VOID_PACKAGES_DIR   Path to the void-packages checkout
EOF
}

info() {
    printf '[build] %s\n' "$*"
}

die() {
    printf '%s\n' "$*" >&2
    exit 1
}

GPU_PROFILE=
KERNEL_VERSION=
EXTRA_ARGS=()

while [ "$#" -gt 0 ]; do
    case "$1" in
        --gpu)
            [ "$#" -ge 2 ] || die "--gpu requires a value"
            GPU_PROFILE="$2"
            shift 2
            ;;
        --kernel)
            [ "$#" -ge 2 ] || die "--kernel requires a value"
            KERNEL_VERSION="$2"
            shift 2
            ;;
        --)
            shift
            EXTRA_ARGS=("$@")
            break
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
done

[ -n "$GPU_PROFILE" ] || die "Missing --gpu"
[ -n "$KERNEL_VERSION" ] || die "Missing --kernel"
[ -x "$DUFF_DIR/d77" ] || die "Missing executable d77 at $DUFF_DIR/d77"
[ -d "$MAIN_REPO" ] || die "Missing XBPS repo: $MAIN_REPO. Run ./scripts/setup-iso-build-env.sh first."

case "$GPU_PROFILE" in
    amd|nvidia) ;;
    *)
        die "Unsupported GPU profile: $GPU_PROFILE"
        ;;
esac

case "$KERNEL_VERSION" in
    6.19|7.0) ;;
    *)
        die "Unsupported kernel version: $KERNEL_VERSION"
        ;;
esac

D77_ARGS=(
    -r "$MAIN_REPO"
    -b plasma
    -k "$KERNEL_VERSION"
)

if [ "$GPU_PROFILE" = "nvidia" ]; then
    [ -d "$NONFREE_REPO" ] || die "Missing nonfree XBPS repo: $NONFREE_REPO. Run ./scripts/setup-iso-build-env.sh first."
    D77_ARGS+=(
        -r "$NONFREE_REPO"
        -g nvidia
    )
fi

if [ "${#EXTRA_ARGS[@]}" -gt 0 ]; then
    D77_ARGS+=(-- "${EXTRA_ARGS[@]}")
else
    D77_ARGS+=(--)
fi

info "Duff Linux repo: $DUFF_DIR"
info "void-packages repo: $VOID_PACKAGES_DIR"
info "Building Plasma ISO for GPU=$GPU_PROFILE kernel=$KERNEL_VERSION"

cd "$DUFF_DIR"
exec sudo ./d77 "${D77_ARGS[@]}"

#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DUFF_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
. "$SCRIPT_DIR/common.sh"

WORKSPACE_DIR=${WORKSPACE_DIR:-$(dirname -- "$DUFF_DIR")}
DEFAULT_VOID_PACKAGES_DIR="$WORKSPACE_DIR/void-packages"
MANAGED_VOID_PACKAGES_DIR=${MANAGED_VOID_PACKAGES_DIR:-"$WORKSPACE_DIR/void-packages-duff-build"}
if [ "${VOID_PACKAGES_DIR+x}" = x ]; then
    VOID_PACKAGES_DIR_EXPLICIT=yes
else
    VOID_PACKAGES_DIR_EXPLICIT=no
fi
VOID_PACKAGES_DIR=${VOID_PACKAGES_DIR:-$(resolve_void_packages_dir \
    "$VOID_PACKAGES_DIR_EXPLICIT" \
    "${VOID_PACKAGES_DIR:-}" \
    "$DEFAULT_VOID_PACKAGES_DIR" \
    "$MANAGED_VOID_PACKAGES_DIR")}
MAIN_REPO="$VOID_PACKAGES_DIR/hostdir/binpkgs"
NONFREE_REPO="$MAIN_REPO/nonfree"
BUILD_HELPER_LOG=${BUILD_HELPER_LOG:-"$DUFF_DIR/build-iso-helper.log"}

usage() {
    cat <<EOF
Usage: $(basename "$0") --gpu amd|nvidia --kernel 6.19|7.0 [-- extra d77 args]

Environment variables:
  WORKSPACE_DIR       Parent directory containing the repos
  VOID_PACKAGES_DIR   Path to the void-packages checkout
  MANAGED_VOID_PACKAGES_DIR
                     Clean auxiliary checkout used when the sibling repo
                     is missing required upstream templates
EOF
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

if [ "${#EXTRA_ARGS[@]}" -gt 0 ]; then
    D77_ARGS+=(-- "${EXTRA_ARGS[@]}")
else
    D77_ARGS+=(--)
fi

main_repo_ready() {
    find "$MAIN_REPO" -maxdepth 1 -type f -name 'calamares-*.xbps' 2>/dev/null | grep -q .
}

dkms_override_ready() {
    local template=$DUFF_DIR/build/srcpkgs/dkms/template
    local version=
    local revision=

    [ -f "$template" ] || return 1

    version=$(sed -n 's/^version=\(.*\)$/\1/p' "$template" | head -n1)
    revision=$(sed -n 's/^revision=\(.*\)$/\1/p' "$template" | head -n1)

    [ -n "$version" ] || return 1
    [ -n "$revision" ] || return 1

    find "$MAIN_REPO" -maxdepth 1 -type f -name "dkms-${version}_${revision}*.xbps" 2>/dev/null | grep -q .
}

nonfree_repo_ready() {
    find "$NONFREE_REPO" -maxdepth 1 -type f 2>/dev/null \
        \( -name 'nvidia-*.xbps' -o -name 'nvidia[0-9]*-*.xbps' \) | grep -q .
}

repositories_ready() {
    main_repo_ready || return 1
    dkms_override_ready || return 1

    if [ "$GPU_PROFILE" = "nvidia" ]; then
        nonfree_repo_ready || return 1
    fi
}

ensure_local_repositories() {
    local setup_args=()
    local status=0

    if void_packages_bootstrap_ready "$VOID_PACKAGES_DIR"; then
        setup_args+=(--skip-bootstrap)
    fi

    append_log_note "$BUILD_HELPER_LOG" "START: Preparing local XBPS repositories"
    WORKSPACE_DIR="$WORKSPACE_DIR" \
    VOID_PACKAGES_DIR="$VOID_PACKAGES_DIR" \
    MANAGED_VOID_PACKAGES_DIR="$MANAGED_VOID_PACKAGES_DIR" \
    "$SCRIPT_DIR/setup-iso-build-env.sh" "${setup_args[@]}" || status=$?

    if [ "$status" -eq 0 ]; then
        append_log_note "$BUILD_HELPER_LOG" "DONE: Preparing local XBPS repositories"
        return 0
    fi

    append_log_note "$BUILD_HELPER_LOG" "FAILED($status): Preparing local XBPS repositories"
    return "$status"
}

run_d77_build() {
    cd "$DUFF_DIR"
    sudo -n ./d77 "${D77_ARGS[@]}"
}

ensure_sudo_session() {
    if sudo -n true 2>/dev/null; then
        return
    fi

    printf 'Sudo authentication is required to run d77.\n'
    sudo -v
}

start_log "$BUILD_HELPER_LOG" "Duff Linux ISO build helper"
append_log_note "$BUILD_HELPER_LOG" "Duff Linux checkout: $DUFF_DIR"
append_log_note "$BUILD_HELPER_LOG" "void-packages checkout: $VOID_PACKAGES_DIR"
append_log_note "$BUILD_HELPER_LOG" "default void-packages checkout: $DEFAULT_VOID_PACKAGES_DIR"
append_log_note "$BUILD_HELPER_LOG" "managed void-packages checkout: $MANAGED_VOID_PACKAGES_DIR"
append_log_note "$BUILD_HELPER_LOG" "GPU profile: $GPU_PROFILE"
append_log_note "$BUILD_HELPER_LOG" "Kernel version: $KERNEL_VERSION"

print_titlecard

if ! repositories_ready; then
    ensure_local_repositories
fi

if [ "$GPU_PROFILE" = "nvidia" ]; then
    D77_ARGS=(
        -r "$MAIN_REPO"
        -r "$NONFREE_REPO"
        -g nvidia
        -b plasma
        -k "$KERNEL_VERSION"
    )
    if [ "${#EXTRA_ARGS[@]}" -gt 0 ]; then
        D77_ARGS+=(-- "${EXTRA_ARGS[@]}")
    else
        D77_ARGS+=(--)
    fi
fi

ensure_sudo_session

run_step 1 1 "Building Duff Linux ISO" "$BUILD_HELPER_LOG" run_d77_build

cat <<EOF

Build complete.

void-packages:   $VOID_PACKAGES_DIR
ISO helper log: $BUILD_HELPER_LOG
d77 build log:  $DUFF_DIR/d77-build.log
EOF

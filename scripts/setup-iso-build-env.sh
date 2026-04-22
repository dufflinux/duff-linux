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
VOID_REMOTE=${VOID_REMOTE:-https://github.com/void-linux/void-packages}
SETUP_LOG=${SETUP_LOG:-"$DUFF_DIR/setup-iso-build-env.log"}

usage() {
    cat <<EOF
Usage: $(basename "$0") [--skip-bootstrap] [--skip-build]

Bootstraps a usable void-packages checkout and builds the local packages
required for Duff Linux ISO generation.

Environment variables:
  WORKSPACE_DIR       Parent directory containing the repos
  VOID_PACKAGES_DIR   Path to the void-packages checkout
  MANAGED_VOID_PACKAGES_DIR
                     Clean auxiliary checkout used when the sibling repo
                     is missing required upstream templates
  VOID_REMOTE         Git URL used if void-packages needs to be cloned
EOF
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Missing required command: %s\n' "$1" >&2
        exit 1
    }
}

ensure_void_packages_checkout() {
    if void_packages_checkout_usable "$VOID_PACKAGES_DIR"; then
        return
    fi

    if [ -d "$VOID_PACKAGES_DIR/.git" ]; then
        die "Existing void-packages checkout is incomplete: $VOID_PACKAGES_DIR
Expected upstream templates such as srcpkgs/nvidia/template are missing.
Either remove that checkout and rerun this script, or set VOID_PACKAGES_DIR to a clean clone."
    fi

    if [ "$VOID_PACKAGES_DIR" = "$MANAGED_VOID_PACKAGES_DIR" ] &&
       void_packages_git_has_required_templates "$DEFAULT_VOID_PACKAGES_DIR"; then
        git clone --shared "$DEFAULT_VOID_PACKAGES_DIR" "$VOID_PACKAGES_DIR"
        return
    fi

    git clone "$VOID_REMOTE" "$VOID_PACKAGES_DIR"
}

ensure_bootstrap() {
    (
        cd "$VOID_PACKAGES_DIR"
        ./xbps-src binary-bootstrap
    )
}

sync_local_srcpkgs() {
    local srcpkg_dir
    local pkg_name

    mkdir -p "$VOID_PACKAGES_DIR/srcpkgs"

    for srcpkg_dir in "$DUFF_DIR"/build/srcpkgs/*; do
        [ -d "$srcpkg_dir" ] || continue
        pkg_name=$(basename "$srcpkg_dir")
        sync_srcpkg_dir "$srcpkg_dir" "$VOID_PACKAGES_DIR/srcpkgs/$pkg_name"
    done
}

sync_srcpkg_dir() {
    local source_dir=$1
    local target_dir=$2

    if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete "$source_dir/" "$target_dir/"
        return
    fi

    rm -rf "$target_dir"
    mkdir -p "$target_dir"
    cp -a "$source_dir"/. "$target_dir"/
}

ensure_restricted_config() {
    local conf_file
    conf_file="$VOID_PACKAGES_DIR/etc/conf"

    mkdir -p "$VOID_PACKAGES_DIR/etc"
    touch "$conf_file"

    if grep -qx 'XBPS_ALLOW_RESTRICTED=yes' "$conf_file"; then
        return
    fi

    printf 'XBPS_ALLOW_RESTRICTED=yes\n' >> "$conf_file"
}

build_package() {
    local pkg=$1

    (
        cd "$VOID_PACKAGES_DIR"
        ./xbps-src pkg "$pkg"
    )
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

    find "$VOID_PACKAGES_DIR/hostdir/binpkgs" -maxdepth 1 -type f \
        -name "dkms-${version}_${revision}*.xbps" 2>/dev/null | grep -q .
}

main_repo_ready() {
    find "$VOID_PACKAGES_DIR/hostdir/binpkgs" -maxdepth 1 -type f -name 'calamares-*.xbps' 2>/dev/null | grep -q .
}

nonfree_repo_ready() {
    find "$VOID_PACKAGES_DIR/hostdir/binpkgs/nonfree" -maxdepth 1 -type f 2>/dev/null \
        \( -name 'nvidia-*.xbps' -o -name 'nvidia[0-9]*-*.xbps' \) | grep -q .
}

verify_repositories() {
    main_repo_ready || die "Expected local repo package missing: $VOID_PACKAGES_DIR/hostdir/binpkgs/calamares-*.xbps"
    dkms_override_ready || die "Expected local repo package missing: $VOID_PACKAGES_DIR/hostdir/binpkgs/dkms-*.xbps"
    nonfree_repo_ready || die "Expected nonfree repo package missing: $VOID_PACKAGES_DIR/hostdir/binpkgs/nonfree/nvidia-*.xbps"
}

SKIP_BOOTSTRAP=no
SKIP_BUILD=no

while [ "$#" -gt 0 ]; do
    case "$1" in
        --skip-bootstrap)
            SKIP_BOOTSTRAP=yes
            ;;
        --skip-build)
            SKIP_BUILD=yes
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

require_command git
require_command bash

print_titlecard
start_log "$SETUP_LOG" "Duff Linux ISO build environment setup"
append_log_note "$SETUP_LOG" "Duff Linux checkout: $DUFF_DIR"
append_log_note "$SETUP_LOG" "void-packages checkout: $VOID_PACKAGES_DIR"
append_log_note "$SETUP_LOG" "default void-packages checkout: $DEFAULT_VOID_PACKAGES_DIR"
append_log_note "$SETUP_LOG" "managed void-packages checkout: $MANAGED_VOID_PACKAGES_DIR"

TOTAL_STEPS=4
[ "$SKIP_BOOTSTRAP" = no ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
[ "$SKIP_BUILD" = no ] && TOTAL_STEPS=$((TOTAL_STEPS + 3))
STEP=0

STEP=$((STEP + 1))
run_step "$STEP" "$TOTAL_STEPS" "Preparing void-packages checkout" "$SETUP_LOG" ensure_void_packages_checkout

if [ "$SKIP_BOOTSTRAP" = no ]; then
    STEP=$((STEP + 1))
    run_step "$STEP" "$TOTAL_STEPS" "Running xbps-src binary-bootstrap" "$SETUP_LOG" ensure_bootstrap
fi

STEP=$((STEP + 1))
run_step "$STEP" "$TOTAL_STEPS" "Syncing Duff Linux templates" "$SETUP_LOG" sync_local_srcpkgs

STEP=$((STEP + 1))
run_step "$STEP" "$TOTAL_STEPS" "Enabling restricted packages" "$SETUP_LOG" ensure_restricted_config

if [ "$SKIP_BUILD" = no ]; then
    STEP=$((STEP + 1))
    run_step "$STEP" "$TOTAL_STEPS" "Building calamares" "$SETUP_LOG" build_package calamares

    STEP=$((STEP + 1))
    run_step "$STEP" "$TOTAL_STEPS" "Building dkms" "$SETUP_LOG" build_package dkms

    STEP=$((STEP + 1))
    run_step "$STEP" "$TOTAL_STEPS" "Building nvidia (nonfree repo)" "$SETUP_LOG" build_package nvidia
fi

STEP=$((STEP + 1))
run_step "$STEP" "$TOTAL_STEPS" "Verifying local repositories" "$SETUP_LOG" verify_repositories

cat <<EOF

Setup complete.

void-packages: $VOID_PACKAGES_DIR
default repo:   $DEFAULT_VOID_PACKAGES_DIR
managed repo:   $MANAGED_VOID_PACKAGES_DIR
main repo:      $VOID_PACKAGES_DIR/hostdir/binpkgs
nonfree repo:   $VOID_PACKAGES_DIR/hostdir/binpkgs/nonfree
setup log:      $SETUP_LOG

Next steps:
  ./scripts/build-amd-6.19.sh
  ./scripts/build-amd-7.0.sh
  ./scripts/build-nvidia-6.19.sh
  ./scripts/build-nvidia-7.0.sh
EOF

#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DUFF_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
WORKSPACE_DIR=${WORKSPACE_DIR:-$(dirname -- "$DUFF_DIR")}
VOID_PACKAGES_DIR=${VOID_PACKAGES_DIR:-"$WORKSPACE_DIR/void-packages"}
VOID_REMOTE=${VOID_REMOTE:-https://github.com/void-linux/void-packages}

usage() {
    cat <<EOF
Usage: $(basename "$0") [--skip-bootstrap] [--skip-build]

Bootstraps a sibling void-packages checkout and builds the local packages
required for Duff Linux ISO generation.

Environment variables:
  WORKSPACE_DIR       Parent directory containing the repos
  VOID_PACKAGES_DIR   Path to the void-packages checkout
  VOID_REMOTE         Git URL used if void-packages needs to be cloned
EOF
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Missing required command: %s\n' "$1" >&2
        exit 1
    }
}

info() {
    printf '[setup] %s\n' "$*"
}

ensure_void_packages_checkout() {
    if [ -d "$VOID_PACKAGES_DIR/.git" ]; then
        info "Using existing void-packages checkout at $VOID_PACKAGES_DIR"
        return
    fi

    info "Cloning void-packages into $VOID_PACKAGES_DIR"
    git clone "$VOID_REMOTE" "$VOID_PACKAGES_DIR"
}

ensure_bootstrap() {
    if [ "$SKIP_BOOTSTRAP" = yes ]; then
        info "Skipping binary bootstrap"
        return
    fi

    info "Running xbps-src binary-bootstrap"
    (
        cd "$VOID_PACKAGES_DIR"
        ./xbps-src binary-bootstrap
    )
}

sync_local_srcpkgs() {
    local srcpkg_dir
    local pkg_name

    info "Syncing Duff Linux templates into void-packages/srcpkgs"
    mkdir -p "$VOID_PACKAGES_DIR/srcpkgs"

    for srcpkg_dir in "$DUFF_DIR"/build/srcpkgs/*; do
        [ -d "$srcpkg_dir" ] || continue
        pkg_name=$(basename "$srcpkg_dir")
        rsync -a --delete "$srcpkg_dir/" "$VOID_PACKAGES_DIR/srcpkgs/$pkg_name/"
    done
}

ensure_restricted_config() {
    local conf_file
    conf_file="$VOID_PACKAGES_DIR/etc/conf"

    mkdir -p "$VOID_PACKAGES_DIR/etc"
    touch "$conf_file"

    if grep -qx 'XBPS_ALLOW_RESTRICTED=yes' "$conf_file"; then
        info "Restricted package support already enabled"
        return
    fi

    info "Enabling restricted package support in $conf_file"
    printf 'XBPS_ALLOW_RESTRICTED=yes\n' >> "$conf_file"
}

build_local_packages() {
    if [ "$SKIP_BUILD" = yes ]; then
        info "Skipping local package build"
        return
    fi

    info "Building local packages: calamares dkms nvidia"
    (
        cd "$VOID_PACKAGES_DIR"
        ./xbps-src pkg calamares dkms nvidia
    )
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
require_command rsync

info "Using Duff Linux checkout at $DUFF_DIR"
ensure_void_packages_checkout
ensure_bootstrap
sync_local_srcpkgs
ensure_restricted_config
build_local_packages

cat <<EOF

Setup complete.

void-packages: $VOID_PACKAGES_DIR
main repo:      $VOID_PACKAGES_DIR/hostdir/binpkgs
nonfree repo:   $VOID_PACKAGES_DIR/hostdir/binpkgs/nonfree

Next steps:
  ./scripts/build-amd-6.19.sh
  ./scripts/build-amd-7.0.sh
  ./scripts/build-nvidia-6.19.sh
  ./scripts/build-nvidia-7.0.sh
EOF

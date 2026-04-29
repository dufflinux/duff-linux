#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DUFF_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
DEFAULT_WORKSPACE_DIR=$(dirname -- "$DUFF_DIR")

IMAGE=${DUFF_CONTAINER_IMAGE:-duff-linux-void-build:latest}
ENGINE=${DUFF_CONTAINER_ENGINE:-}
WORKSPACE_DIR=${WORKSPACE_DIR:-$DEFAULT_WORKSPACE_DIR}
REBUILD=no
SKIP_IMAGE_BUILD=no
ROOTFUL=no
CONTAINER_COMMAND=()
CONTAINER_ACTION=

usage() {
    cat <<EOF
Usage: $(basename "$0") [options] [shell|setup|build-amd-6.19|build-amd-7.0|build-nvidia-6.19|build-nvidia-7.0|clean|-- command ...]

Runs Duff Linux build commands inside a Void Linux container while keeping the
host distribution clean.
The ISO build shortcuts use rootful Podman automatically because ISO assembly
needs loop devices, mknod, mounts, and unmounts.

Common examples:
  $(basename "$0") shell
  $(basename "$0") setup
  $(basename "$0") build-amd-7.0
  $(basename "$0") clean
  $(basename "$0") --rootful clean
  $(basename "$0") -- ./scripts/build-iso.sh --gpu amd --kernel 7.0 -- -K

Options:
  --engine podman|docker  Container engine to use
  --image name           Image tag to build/run (default: $IMAGE)
  --workspace path       Parent directory containing duff-linux and void-packages
  --rebuild              Rebuild the container image before running
  --no-build             Do not build the image before running
  --rootful              Run the container engine through sudo
  -h, --help             Show this help

Environment:
  DUFF_CONTAINER_ENGINE   Default container engine
  DUFF_CONTAINER_IMAGE    Default image tag
  WORKSPACE_DIR           Default workspace mount
  VOID_PACKAGES_DIR       Optional void-packages checkout path passed through
EOF
}

find_engine() {
    if [ -n "$ENGINE" ]; then
        command -v "$ENGINE" >/dev/null 2>&1 || {
            printf 'Configured container engine not found: %s\n' "$ENGINE" >&2
            exit 1
        }
        printf '%s\n' "$ENGINE"
        return
    fi

    if command -v podman >/dev/null 2>&1; then
        printf 'podman\n'
        return
    fi

    if command -v docker >/dev/null 2>&1; then
        printf 'docker\n'
        return
    fi

    cat >&2 <<EOF
Missing container engine: install Podman or Docker, then rerun this script.
On Bluefin, prefer the actual Podman CLI/package over podman-tui by itself.
EOF
    exit 1
}

engine_image_exists() {
    case "$ENGINE" in
        docker)
            "${ENGINE_CMD[@]}" image inspect "$IMAGE" >/dev/null 2>&1
            ;;
        *)
            "${ENGINE_CMD[@]}" image exists "$IMAGE" >/dev/null 2>&1
            ;;
    esac
}

build_image() {
    printf 'Building Void build image: %s\n' "$IMAGE"
    "${ENGINE_CMD[@]}" build \
        -t "$IMAGE" \
        -f "$DUFF_DIR/build/container/Containerfile" \
        "$DUFF_DIR/build"
}

container_command_for() {
    local command_name=${1:-shell}
    [ "$#" -gt 0 ] && shift || true

    case "$command_name" in
        shell)
            CONTAINER_ACTION=shell
            CONTAINER_COMMAND=(/bin/bash "$@")
            ;;
        setup)
            CONTAINER_ACTION=setup
            CONTAINER_COMMAND=(./scripts/setup-iso-build-env.sh "$@")
            ;;
        build-amd-6.19|build-amd-7.0|build-nvidia-6.19|build-nvidia-7.0)
            CONTAINER_ACTION=build
            CONTAINER_COMMAND=("./scripts/${command_name}.sh" "$@")
            ;;
        clean)
            CONTAINER_ACTION=clean
            CONTAINER_COMMAND=()
            ;;
        --)
            [ "$#" -gt 0 ] || {
                printf 'Missing command after --\n' >&2
                exit 1
            }
            CONTAINER_ACTION=custom
            CONTAINER_COMMAND=("$@")
            ;;
        *)
            CONTAINER_ACTION=custom
            CONTAINER_COMMAND=("$command_name" "$@")
            ;;
    esac
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --engine)
            [ "$#" -ge 2 ] || {
                printf '%s requires a value\n' "$1" >&2
                exit 1
            }
            ENGINE=$2
            shift 2
            ;;
        --image)
            [ "$#" -ge 2 ] || {
                printf '%s requires a value\n' "$1" >&2
                exit 1
            }
            IMAGE=$2
            shift 2
            ;;
        --workspace)
            [ "$#" -ge 2 ] || {
                printf '%s requires a value\n' "$1" >&2
                exit 1
            }
            WORKSPACE_DIR=$2
            shift 2
            ;;
        --rebuild)
            REBUILD=yes
            shift
            ;;
        --no-build)
            SKIP_IMAGE_BUILD=yes
            shift
            ;;
        --rootful)
            ROOTFUL=yes
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            container_command_for -- "$@"
            break
            ;;
        *)
            container_command_for "$@"
            break
            ;;
    esac
done

if [ "${#CONTAINER_COMMAND[@]}" -eq 0 ] && [ -z "$CONTAINER_ACTION" ]; then
    container_command_for shell
fi

ENGINE=$(find_engine)
if [ "$CONTAINER_ACTION" = clean ]; then
    if [ "$ROOTFUL" = yes ]; then
        ENGINE_CMD=(sudo "$ENGINE")
    else
        ENGINE_CMD=("$ENGINE")
    fi
    "${ENGINE_CMD[@]}" image rm -f "$IMAGE"
    exit 0
fi

if [ "$ENGINE" = podman ] && [ "$CONTAINER_ACTION" = build ] && [ "$ROOTFUL" = no ]; then
    printf 'ISO assembly needs loop devices, mknod, mounts, and unmounts; switching Podman to rootful mode.\n'
    ROOTFUL=yes
fi

if [ "$ROOTFUL" = yes ]; then
    ENGINE_CMD=(sudo "$ENGINE")
else
    ENGINE_CMD=("$ENGINE")
fi

if [ "$SKIP_IMAGE_BUILD" = no ]; then
    if [ "$REBUILD" = yes ] || ! engine_image_exists; then
        build_image
    fi
fi

WORKSPACE_DIR=$(cd -- "$WORKSPACE_DIR" && pwd)
DUFF_DIR=$(cd -- "$DUFF_DIR" && pwd)

HOST_UID=${SUDO_UID:-$(id -u)}
HOST_GID=${SUDO_GID:-$(id -g)}

TTY_ARGS=()
if [ -t 0 ] && [ -t 1 ]; then
    TTY_ARGS=(-it)
fi

RUN_ARGS=(
    run
    --rm
    "${TTY_ARGS[@]}"
    --privileged
    --security-opt label=disable
    -e "DUFF_HOST_UID=$HOST_UID"
    -e "DUFF_HOST_GID=$HOST_GID"
    -e "WORKSPACE_DIR=$WORKSPACE_DIR"
    -v "$WORKSPACE_DIR:$WORKSPACE_DIR"
    -w "$DUFF_DIR"
)

if [ "$ENGINE" = podman ] && [ "$ROOTFUL" = no ]; then
    RUN_ARGS+=(--userns=keep-id --user root:root)
fi

if [ "$ENGINE" = podman ] && [ "$ROOTFUL" = yes ]; then
    sudo modprobe loop 2>/dev/null || true
    for device in /dev/loop-control /dev/loop[0-9]*; do
        [ -e "$device" ] || continue
        RUN_ARGS+=(--device "$device")
    done
fi

if [ "${VOID_PACKAGES_DIR+x}" = x ]; then
    RUN_ARGS+=(-e "VOID_PACKAGES_DIR=$VOID_PACKAGES_DIR")
fi

if [ "${MANAGED_VOID_PACKAGES_DIR+x}" = x ]; then
    RUN_ARGS+=(-e "MANAGED_VOID_PACKAGES_DIR=$MANAGED_VOID_PACKAGES_DIR")
fi

if [ "${VOID_REMOTE+x}" = x ]; then
    RUN_ARGS+=(-e "VOID_REMOTE=$VOID_REMOTE")
fi

"${ENGINE_CMD[@]}" "${RUN_ARGS[@]}" "$IMAGE" "${CONTAINER_COMMAND[@]}"

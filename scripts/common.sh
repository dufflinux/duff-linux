#!/bin/bash

die() {
    printf '%s\n' "$*" >&2
    exit 1
}

print_titlecard() {
    local title=${1:-Duff Linux ISO Generator}

    [ "${DUFF_ISO_TITLE_SHOWN:-no}" = yes ] && return 0

    export DUFF_ISO_TITLE_SHOWN=yes

    printf '\n%s\n' "$title"
    printf '%*s\n\n' "${#title}" '' | tr ' ' '='
}

start_log() {
    local log_file=$1
    local title=$2

    mkdir -p "$(dirname "$log_file")"
    : > "$log_file"
    printf '[%s] %s\n' "$(date -u '+%Y-%m-%d %H:%M:%S UTC')" "$title" >> "$log_file"
}

append_log_note() {
    local log_file=$1
    shift
    printf '[%s] %s\n' "$(date -u '+%Y-%m-%d %H:%M:%S UTC')" "$*" >> "$log_file"
}

run_step() {
    local step_num=$1
    local step_total=$2
    local label=$3
    local log_file=$4
    shift 4

    local spinner='|/-\'
    local spinner_index=0
    local pid
    local status
    local frame

    append_log_note "$log_file" "START: $label"

    if [ -t 1 ]; then
        (
            "$@"
        ) >> "$log_file" 2>&1 &
        pid=$!

        while kill -0 "$pid" 2>/dev/null; do
            frame=${spinner:$spinner_index:1}
            printf '\r[%d/%d] %s %s' "$step_num" "$step_total" "$label" "$frame"
            spinner_index=$(((spinner_index + 1) % 4))
            sleep 0.1
        done

        status=0
        wait "$pid" || status=$?
    else
        printf '[%d/%d] %s...\n' "$step_num" "$step_total" "$label"
        status=0
        "$@" >> "$log_file" 2>&1 || status=$?
    fi

    if [ "$status" -eq 0 ]; then
        append_log_note "$log_file" "DONE: $label"
        if [ -t 1 ]; then
            printf '\r[%d/%d] %s done\n' "$step_num" "$step_total" "$label"
        else
            printf '[%d/%d] %s done\n' "$step_num" "$step_total" "$label"
        fi
        return 0
    fi

    append_log_note "$log_file" "FAILED($status): $label"
    if [ -t 1 ]; then
        printf '\r[%d/%d] %s failed\n' "$step_num" "$step_total" "$label" >&2
    else
        printf '[%d/%d] %s failed\n' "$step_num" "$step_total" "$label" >&2
    fi
    printf 'See log: %s\n' "$log_file" >&2
    return "$status"
}

void_packages_checkout_usable() {
    local dir=$1

    [ -d "$dir/.git" ] || return 1
    [ -x "$dir/xbps-src" ] || return 1
    [ -f "$dir/srcpkgs/dkms/template" ] || return 1
    [ -f "$dir/srcpkgs/nvidia/template" ] || return 1
    [ -f "$dir/srcpkgs/xbps-triggers/template" ] || return 1
}

void_packages_git_has_required_templates() {
    local dir=$1

    [ -d "$dir/.git" ] || return 1
    git -C "$dir" cat-file -e HEAD:xbps-src 2>/dev/null || return 1
    git -C "$dir" cat-file -e HEAD:srcpkgs/dkms/template 2>/dev/null || return 1
    git -C "$dir" cat-file -e HEAD:srcpkgs/nvidia/template 2>/dev/null || return 1
    git -C "$dir" cat-file -e HEAD:srcpkgs/xbps-triggers/template 2>/dev/null || return 1
}

void_packages_bootstrap_ready() {
    local dir=$1

    [ -d "$dir/masterdir-x86_64" ]
}

resolve_void_packages_dir() {
    local explicit_choice=$1
    local requested_dir=$2
    local default_dir=$3
    local managed_dir=$4

    if [ "$explicit_choice" = yes ]; then
        printf '%s\n' "$requested_dir"
        return
    fi

    if void_packages_checkout_usable "$default_dir"; then
        printf '%s\n' "$default_dir"
        return
    fi

    if void_packages_checkout_usable "$managed_dir"; then
        printf '%s\n' "$managed_dir"
        return
    fi

    if [ -d "$default_dir/.git" ]; then
        printf '%s\n' "$managed_dir"
        return
    fi

    printf '%s\n' "$default_dir"
}

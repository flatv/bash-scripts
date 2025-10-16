#!/bin/bash

# Утилиты
check_dependencies() {
    local missing=()
    for dep in "$@"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Отсутствуют зависимости: ${missing[*]}"
        return 1
    fi
    return 0
}

validate_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_error "Директория не существует: $dir"
        return 1
    fi
    if [[ ! -r "$dir" ]]; then
        log_error "Нет прав на чтение директории: $dir"
        return 1
    fi
    return 0
}

create_temp_file() {
    local prefix="${1:-temp}"
    mkdir -p "$BASH_SCRIPTS_ROOT/var/tmp"
    mktemp "$BASH_SCRIPTS_ROOT/var/tmp/${prefix}.XXXXXX"
}

cleanup_temp_files() {
    find "$BASH_SCRIPTS_ROOT/var/tmp" -name "*.XXXXXX" -mtime +1 -delete 2>/dev/null || true
}

get_script_root() {
    if [[ -n "$BASH_SCRIPTS_ROOT" && -d "$BASH_SCRIPTS_ROOT" ]]; then
        echo "$BASH_SCRIPTS_ROOT"
    else
        echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    fi
}

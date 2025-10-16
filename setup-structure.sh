#!/bin/bash
# setup-structure.sh

create_structure() {
    local base_dir="${1:-$HOME/bash-scripts}"
    
    echo "Создаю структуру в $base_dir..."
    
    # Основные директории
    mkdir -p "$base_dir"/{bin,lib/core,lib/git,lib/config,etc,var/{log,cache,tmp},tests/{unit,integration}}
    
    # Создаем основные файлы
    touch "$base_dir/README.md"
    touch "$base_dir/etc/git-servers.conf"
    touch "$base_dir/etc/projects.conf"
    
    echo "Структура создана в $base_dir"
}

create_structure "$@"

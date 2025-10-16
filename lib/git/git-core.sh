#!/bin/bash

# Базовые Git функции
find_git_repos() {
    local base_dir="$1"
    local repos=()
    
    if [[ ! -d "$base_dir" ]]; then
        log_error "Директория не существует: $base_dir"
        return 1
    fi
    
    while IFS= read -r -d '' git_dir; do
        local repo_dir=$(dirname "$git_dir")
        # Проверяем, что это действительно git репозиторий
        if git -C "$repo_dir" rev-parse --git-dir > /dev/null 2>&1; then
            repos+=("$repo_dir")
        fi
    done < <(find "$base_dir" -name ".git" -type d -print0 2>/dev/null)
    
    printf "%s\n" "${repos[@]}"
}

get_repo_info() {
    local repo_dir="$1"
    cd "$repo_dir" || return 1
    
    local remote_url=$(git config --get remote.origin.url 2>/dev/null)
    local current_branch=$(git branch --show-current 2>/dev/null)
    local repo_name=$(basename "$repo_dir")
    
    echo "$repo_name|$current_branch|$remote_url"
}

is_git_repo() {
    local repo_dir="$1"
    [[ -d "$repo_dir/.git" ]] && git -C "$repo_dir" rev-parse --git-dir > /dev/null 2>&1
}

get_current_branch() {
    local repo_dir="$1"
    git -C "$repo_dir" branch --show-current 2>/dev/null
}

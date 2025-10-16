#!/bin/bash

# Валидация
validate_git_branch() {
    local branch="$1"
    if [[ -z "$branch" ]]; then
        log_error "Имя ветки не может быть пустым"
        return 1
    fi
    
    # Проверяем допустимые символы в имени ветки
    if [[ ! "$branch" =~ ^[a-zA-Z0-9/_.-]+$ ]]; then
        log_error "Недопустимые символы в имени ветки: $branch"
        return 1
    fi
    
    return 0
}

validate_property_name() {
    local prop_name="$1"
    if [[ -z "$prop_name" ]]; then
        log_error "Имя свойства не может быть пустым"
        return 1
    fi
    return 0
}

check_git_connectivity() {
    local repo_dir="$1"
    cd "$repo_dir" || return 1
    
    if ! git ls-remote origin > /dev/null 2>&1; then
        log_warning "Нет подключения к origin в $(basename "$repo_dir")"
        return 1
    fi
    return 0
}

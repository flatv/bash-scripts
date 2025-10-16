#!/bin/bash

# Функции для работы с ветками
ensure_repo_updated() {
    local repo_dir="$1"
    local target_branch="$2"
    local pull_changes="${3:-true}"
    
    if ! is_git_repo "$repo_dir"; then
        log_warning "Не Git репозиторий: $(basename "$repo_dir")"
        return 1
    fi
    
    cd "$repo_dir" || return 1
    
    local repo_name=$(basename "$repo_dir")
    local current_branch=$(get_current_branch "$repo_dir")
    
    log_info "Репо: $repo_name | Текущая ветка: $current_branch | Целевая: $target_branch"
    
    # Получаем актуальную информацию с origin
    if ! git fetch origin; then
        log_warning "Не удалось получить данные из origin"
    fi
    
    # Проверяем существование ветки
    if ! git show-ref --verify --quiet "refs/heads/$target_branch"; then
        if git show-ref --verify --quiet "refs/remotes/origin/$target_branch"; then
            log_info "Создаем локальную ветку $target_branch из origin/$target_branch"
            if ! git checkout -b "$target_branch" "origin/$target_branch"; then
                log_error "Не удалось создать ветку $target_branch"
                return 1
            fi
        else
            log_error "Ветка $target_branch не существует локально и в origin"
            return 1
        fi
    fi
    
    # Переключаемся на целевую ветку если нужно
    if [[ "$current_branch" != "$target_branch" ]]; then
        log_info "Переключаемся с $current_branch на $target_branch"
        if ! git checkout "$target_branch"; then
            log_error "Не удалось переключиться на ветку $target_branch"
            return 1
        fi
    fi
    
    # Проверяем актуальность и обновляем если нужно
    if [[ "$pull_changes" == "true" ]]; then
        local local_behind=0
        local local_ahead=0
        
        if git show-ref --verify --quiet "refs/remotes/origin/$target_branch"; then
            local_behind=$(git rev-list --count "origin/$target_branch..$target_branch" 2>/dev/null || echo 0)
            local_ahead=$(git rev-list --count "$target_branch..origin/$target_branch" 2>/dev/null || echo 0)
        fi
        
        if [[ $local_behind -gt 0 ]]; then
            log_info "Обновляем ветку ($local_behind коммитов позади)"
            if ! git pull --ff-only origin "$target_branch"; then
                log_error "Конфликт при обновлении ветки $target_branch"
                return 1
            fi
            log_success "Ветка обновлена"
        elif [[ $local_ahead -gt 0 ]]; then
            log_warning "Опережает origin на $local_ahead коммитов"
        else
            log_success "Актуальна"
        fi
    fi
    
    return 0
}

create_new_branch() {
    local repo_dir="$1"
    local base_branch="$2"
    local new_branch="$3"
    local push_to_origin="${4:-false}"
    
    log_action "Создаем ветку $new_branch из $base_branch в $(basename "$repo_dir")"
    
    if ! ensure_repo_updated "$repo_dir" "$base_branch"; then
        return 1
    fi
    
    cd "$repo_dir" || return 1
    
    # Проверяем, существует ли уже новая ветка
    if git show-ref --verify --quiet "refs/heads/$new_branch"; then
        log_warning "Ветка $new_branch уже существует"
        if git checkout "$new_branch"; then
            log_success "Переключились на существующую ветку $new_branch"
            return 0
        else
            log_error "Не удалось переключиться на ветку $new_branch"
            return 1
        fi
    fi
    
    # Создаем новую ветку
    if git checkout -b "$new_branch"; then
        log_success "Ветка $new_branch создана"
        
        # Пушим в origin если нужно
        if [[ "$push_to_origin" == "true" ]]; then
            if git push -u origin "$new_branch"; then
                log_success "Ветка отправлена в origin"
            else
                log_error "Не удалось отправить ветку в origin"
                return 1
            fi
        fi
        
        return 0
    else
        log_error "Не удалось создать ветку $new_branch"
        return 1
    fi
}

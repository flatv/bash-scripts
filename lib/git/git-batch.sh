#!/bin/bash

# Массовые Git операции
batch_operation() {
    local base_dir="$1"
    local operation="$2"  # Функция для выполнения
    local description="$3"
    shift 3
    local extra_args=("$@")
    
    local repos=()
    while IFS= read -r repo; do
        repos+=("$repo")
    done < <(find_git_repos "$base_dir")
    
    local total=${#repos[@]}
    local success_count=0
    local fail_count=0
    local skipped_count=0
    
    if [[ $total -eq 0 ]]; then
        log_warning "В директории $base_dir не найдено Git репозиториев"
        return 1
    fi
    
    log_action "$description (найдено репозиториев: $total)"
    
    for repo in "${repos[@]}"; do
        echo
        log_info "Обрабатываем: $(basename "$repo")"
        
        # Вызываем операцию с дополнительными аргументами
        if "$operation" "$repo" "${extra_args[@]}"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    # Вывод результатов
    echo
    log_action "Результаты $description:"
    log_success "Успешно: $success_count"
    if [[ $fail_count -gt 0 ]]; then
        log_error "Ошибки: $fail_count"
    else
        log_info "Ошибки: $fail_count"
    fi
    log_info "Всего: $total"
    
    return $((fail_count > 0 ? 1 : 0))
}

batch_create_release_branches() {
    local base_dir="$1"
    local base_branch="$2"
    local release_branch="$3"
    local push_to_origin="${4:-true}"
    
    log_action "Массовое создание релизных веток: $release_branch из $base_branch"
    
    if ! validate_git_branch "$base_branch" || ! validate_git_branch "$release_branch"; then
        return 1
    fi
    
    batch_operation "$base_dir" "create_new_branch" "Создание ветки $release_branch" "$base_branch" "$release_branch" "$push_to_origin"
}

batch_update_branches() {
    local base_dir="$1"
    local target_branch="$2"
    
    log_action "Массовое обновление веток: $target_branch"
    
    if ! validate_git_branch "$target_branch"; then
        return 1
    fi
    
    batch_operation "$base_dir" "ensure_repo_updated" "Обновление ветки $target_branch" "$target_branch"
}

show_repos_status() {
    local base_dir="$1"
    local target_branch="${2:-}"
    
    log_action "Статус репозиториев в: $base_dir"
    
    local repos=()
    while IFS= read -r repo; do
        repos+=("$repo")
    done < <(find_git_repos "$base_dir")
    
    if [[ ${#repos[@]} -eq 0 ]]; then
        log_warning "Git репозитории не найдены"
        return 1
    fi
    
    printf "%-40s %-20s %-15s %-10s %-10s\n" "Репозиторий" "Текущая ветка" "Отставание" "Опережение" "Неотправлено"
    echo "---------------------------------------------------------------------------------------------------"
    
    for repo in "${repos[@]}"; do
        cd "$repo" || continue
        
        local repo_name=$(basename "$repo")
        local current_branch=$(get_current_branch "$repo")
        local remote_url=$(git config --get remote.origin.url | sed 's|.*/||' | sed 's|.git$||')
        
        local behind=0
        local ahead=0
        local unpushed=0
        
        # Если указана целевая ветка, показываем разницу
        if [[ -n "$target_branch" && "$current_branch" == "$target_branch" ]]; then
            git fetch origin > /dev/null 2>&1
            
            if git show-ref --verify --quiet "refs/remotes/origin/$target_branch"; then
                behind=$(git rev-list --count "origin/$target_branch..$target_branch" 2>/dev/null || echo 0)
                ahead=$(git rev-list --count "$target_branch..origin/$target_branch" 2>/dev/null || echo 0)
            fi
            
            # Количество неотправленных коммитов
            unpushed=$(git log --oneline "origin/$target_branch..$target_branch" 2>/dev/null | wc -l)
        fi
        
        printf "%-40s %-20s %-15s %-10s %-10s\n" "$repo_name" "$current_branch" "$behind" "$ahead" "$unpushed"
    done
}

#!/bin/bash

# Определяем корневую директорию скриптов
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export BASH_SCRIPTS_ROOT="$SCRIPT_ROOT"

# Подключаем библиотеки
source "$SCRIPT_ROOT/lib/core/logging.sh"
source "$SCRIPT_ROOT/lib/core/utils.sh"
source "$SCRIPT_ROOT/lib/core/validation.sh"
source "$SCRIPT_ROOT/lib/git/git-core.sh"
source "$SCRIPT_ROOT/lib/git/git-batch.sh"

# Функции для поиска свойств
search_properties_in_repo() {
    local repo_dir="$1"
    local prop_name="$2"
    local prop_value="$3"
    local search_source="$4"
    
    cd "$repo_dir" || return 1
    
    local project_name=$(basename "$repo_dir")
    
    # Получаем имя из pom.xml если есть
    if [[ -f "pom.xml" ]]; then
        local artifact_name=$(grep -oP '<artifactId>\K[^<]+' "pom.xml" | head -1)
        if [[ -n "$artifact_name" ]]; then
            project_name="$artifact_name"
        fi
    fi
    
    log_info "Ищем в проекте: $project_name"
    
    local found_matches=false
    local match_count=0
    
    # Функция поиска в файлах
    search_in_files() {
        local search_patterns=("$@")
        local pattern_str=$(printf "%s " "${search_patterns[@]}")
        
        while IFS= read -r -d '' file; do
            # Пропускаем бинарные файлы и папки target
            if [[ "$file" == *"/target/"* ]] || \
               [[ "$file" == *"/build/"* ]] || \
               { file "$file" 2>/dev/null | grep -q "binary"; }; then
                continue
            fi
            
            while IFS=: read -r line_num line_content; do
                if [[ "$line_content" =~ $prop_value ]]; then
                    # Дополнительная проверка для релевантности
                    local is_relevant=false
                    
                    # Для конфигурационных файлов
                    if [[ "$file" == *.yaml || "$file" == *.yml || "$file" == *.properties ]]; then
                        [[ "$line_content" =~ $prop_name ]] && is_relevant=true
                    # Для XML файлов
                    elif [[ "$file" == *.xml ]]; then
                        [[ "$line_content" =~ [Ll]evel ]] && is_relevant=true
                    # Для Java файлов
                    elif [[ "$file" == *.java ]]; then
                        [[ "$line_content" =~ [Dd][Ee][Bb][Uu][Gg]|[Ll][Oo][Gg] ]] && is_relevant=true
                    else
                        is_relevant=true
                    fi
                    
                    if [[ "$is_relevant" == "true" ]]; then
                        if [[ "$found_matches" == "false" ]]; then
                            echo -e "${GREEN}📁 Проект: $project_name${NC}"
                            found_matches=true
                        fi
                        ((match_count++))
                        local rel_path=$(realpath --relative-to="$repo_dir" "$file")
                        echo -e "   📄 ${YELLOW}$rel_path:${line_num}${NC}"
                        echo -e "      ${BLUE}$(echo "$line_content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')${NC}"
                    fi
                fi
            done < <(grep -n "$prop_value" "$file" 2>/dev/null || true)
        done < <(eval "find \"$repo_dir\" -type f \( ${pattern_str} \) -not -path \"*/.git/*\" -print0 2>/dev/null")
    }
    
    # Паттерны для поиска
    local resource_patterns=(
        "-name \"application*.yaml\""
        "-name \"application*.yml\""
        "-name \"application*.properties\""
        "-name \"logback*.xml\""
        "-name \"log4j*.properties\""
        "-name \"logging.properties\""
    )
    
    local source_patterns=(
        "-name \"*.java\""
    )
    
    # Поиск в ресурсах
    search_in_files "${resource_patterns[@]}"
    
    # Поиск в исходниках если нужно
    if [[ "$search_source" == "true" ]]; then
        search_in_files "${source_patterns[@]}"
    fi
    
    if [[ "$found_matches" == "true" ]]; then
        echo -e "   ${GREEN}Найдено совпадений: $match_count${NC}"
        echo
        return 0
    else
        log_info "Совпадений не найдено"
        return 1
    fi
}

find_properties_in_all_repos() {
    local dir="$1" 
    local prop_name="$2" 
    local prop_value="$3" 
    local branch="$4" 
    local search_source="$5"
    
    # Сначала обновляем все репозитории
    log_action "Подготовка репозиториев (обновление ветки $branch)..."
    if ! batch_update_branches "$dir" "$branch"; then
        log_error "Не удалось обновить некоторые репозитории"
    fi
    
    # Затем ищем свойства
    log_action "Поиск свойств: $prop_name = $prop_value"
    
    local repos=()
    while IFS= read -r repo; do
        repos+=("$repo")
    done < <(find_git_repos "$dir")
    
    local total=${#repos[@]}
    local found_count=0
    
    if [[ $total -eq 0 ]]; then
        log_warning "В директории $dir не найдено Git репозиториев"
        return 1
    fi
    
    for repo in "${repos[@]}"; do
        echo
        if search_properties_in_repo "$repo" "$prop_name" "$prop_value" "$search_source"; then
            ((found_count++))
        fi
    done
    
    echo
    log_action "Итоги поиска:"
    log_success "Проектов с совпадениями: $found_count"
    log_info "Всего проектов: $total"
}

main() {
    # Проверяем зависимости
    check_dependencies "git" "grep" "find" "realpath" "file" || exit 1
    
    if [[ $# -lt 4 ]]; then
        log_error "Недостаточно аргументов"
        show_usage
        exit 1
    fi
    
    local dir="$1"
    local prop_name="$2"
    local prop_value="$3"
    local branch="$4"
    local search_source="false"
    
    # Проверяем опцию --source
    for arg in "$@"; do
        if [[ "$arg" == "--source" ]]; then
            search_source="true"
            break
        fi
    done
    
    # Валидация
    validate_directory "$dir" || exit 1
    validate_git_branch "$branch" || exit 1
    validate_property_name "$prop_name" || exit 1
    
    # Запускаем поиск
    find_properties_in_all_repos "$dir" "$prop_name" "$prop_value" "$branch" "$search_source"
}

show_usage() {
    cat << EOF
Usage: $(basename "$0") <directory> <property_name> <property_value> <branch> [--source]

Search for properties in all Git repositories.

Arguments:
  directory       Root directory containing Git repositories
  property_name   Property name to search for
  property_value  Property value to search for  
  branch          Git branch to check out and search in
  --source        Also search in source files (.java)

Examples:
  $(basename "$0") /mnt/c/projects logging.level DEBUG develop
  $(basename "$0") /mnt/c/projects level DEBUG main --source
  $(basename "$0") /mnt/c/projects root.level DEBUG feature/logging
EOF
}

# Запуск
main "$@"

#!/bin/bash

# Определяем корневую директорию скриптов
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export BASH_SCRIPTS_ROOT="$SCRIPT_ROOT"

# Подключаем основные библиотеки
source "$SCRIPT_ROOT/lib/core/logging.sh"
source "$SCRIPT_ROOT/lib/core/utils.sh"
source "$SCRIPT_ROOT/lib/core/validation.sh"

# Подключаем Git библиотеки
source "$SCRIPT_ROOT/lib/git/git-core.sh"
source "$SCRIPT_ROOT/lib/git/git-branches.sh"
source "$SCRIPT_ROOT/lib/git/git-batch.sh"

# Подключаем конфигурацию
source "$SCRIPT_ROOT/etc/git-servers.conf" 2>/dev/null || true
source "$SCRIPT_ROOT/etc/projects.conf" 2>/dev/null || true

# Глобальные переменные
COMMAND=""
DIRECTORY=""
BASE_BRANCH=""
NEW_BRANCH=""
TARGET_BRANCH=""
PUSH_TO_ORIGIN="true"

parse_arguments() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    COMMAND="$1"
    shift
    
    case "$COMMAND" in
        "create-release")
            if [[ $# -lt 3 ]]; then
                log_error "Недостаточно аргументов для create-release"
                show_usage
                exit 1
            fi
            DIRECTORY="$1"
            BASE_BRANCH="$2"
            NEW_BRANCH="$3"
            shift 3
            if [[ "${1:-}" == "--no-push" ]]; then
                PUSH_TO_ORIGIN="false"
            fi
            ;;
            
        "update")
            if [[ $# -lt 2 ]]; then
                log_error "Недостаточно аргументов для update"
                show_usage
                exit 1
            fi
            DIRECTORY="$1"
            TARGET_BRANCH="$2"
            ;;
            
        "status")
            if [[ $# -lt 1 ]]; then
                log_error "Недостаточно аргументов для status"
                show_usage
                exit 1
            fi
            DIRECTORY="$1"
            TARGET_BRANCH="${2:-}"
            ;;
            
        *)
            log_error "Неизвестная команда: $COMMAND"
            show_usage
            exit 1
            ;;
    esac
}

show_usage() {
    cat << EOF
Usage: $(basename "$0") <command> [options]

Commands:
  create-release <dir> <base_branch> <new_branch> [--no-push]
    Создает новую ветку во всех репозиториях

  update <dir> <branch>
    Обновляет указанную ветку во всех репозиториях

  status <dir> [branch]
    Показывает статус всех репозиториев

Options:
  --no-push  Не пушить созданные ветки в origin (только для create-release)

Examples:
  $(basename "$0") create-release /mnt/c/projects main release/1.0.0
  $(basename "$0") update /mnt/c/projects develop
  $(basename "$0") status /mnt/c/projects
  $(basename "$0") status /mnt/c/projects develop
EOF
}

main() {
    # Проверяем зависимости
    check_dependencies "git" "find" "realpath" || exit 1
    
    # Парсим аргументы
    parse_arguments "$@"
    
    # Валидируем директорию
    validate_directory "$DIRECTORY" || exit 1
    
    # Выполняем команду
    case "$COMMAND" in
        "create-release") 
            batch_create_release_branches "$DIRECTORY" "$BASE_BRANCH" "$NEW_BRANCH" "$PUSH_TO_ORIGIN"
            ;;
        "update") 
            batch_update_branches "$DIRECTORY" "$TARGET_BRANCH" 
            ;;
        "status") 
            show_repos_status "$DIRECTORY" "$TARGET_BRANCH" 
            ;;
    esac
}

# Запуск
main "$@"

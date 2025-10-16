#!/bin/bash

# Логирование
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Уровни логирования
LOG_LEVEL=${LOG_LEVEL:-"INFO"}

log() {
    local level="$1"
    local message="$2"
    local color="$3"
    
    case "$LOG_LEVEL" in
        "DEBUG") [[ "$level" =~ ^(DEBUG|INFO|SUCCESS|WARNING|ERROR)$ ]] && echo -e "${color}${message}${NC}" ;;
        "INFO") [[ "$level" =~ ^(INFO|SUCCESS|WARNING|ERROR)$ ]] && echo -e "${color}${message}${NC}" ;;
        "WARNING") [[ "$level" =~ ^(WARNING|ERROR)$ ]] && echo -e "${color}${message}${NC}" ;;
        "ERROR") [[ "$level" =~ ^(ERROR)$ ]] && echo -e "${color}${message}${NC}" ;;
        *) echo -e "${color}${message}${NC}" ;;
    esac
}

log_info() { log "INFO" "ℹ️  $1" "$BLUE"; }
log_success() { log "SUCCESS" "✅ $1" "$GREEN"; }
log_warning() { log "WARNING" "⚠️  $1" "$YELLOW"; }
log_error() { log "ERROR" "❌ $1" "$RED"; }
log_debug() { log "DEBUG" "🐛 $1" "$PURPLE"; }
log_action() { log "INFO" "🚀 $1" "$CYAN"; }

# Логирование в файл
log_to_file() {
    local message="$1"
    local log_file="${2:-$BASH_SCRIPTS_ROOT/var/log/operations.log}"
    mkdir -p "$(dirname "$log_file")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

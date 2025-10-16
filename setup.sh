#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASH_SCRIPTS_ROOT="$SCRIPT_DIR"

echo "🐚 Установка Bash Scripts Collection..."
echo "📁 Директория установки: $BASH_SCRIPTS_ROOT"

# Создаем директории
echo "📂 Создаем структуру директорий..."
mkdir -p {"$BASH_SCRIPTS_ROOT/bin","$BASH_SCRIPTS_ROOT/lib/core","$BASH_SCRIPTS_ROOT/lib/git","$BASH_SCRIPTS_ROOT/lib/config","$BASH_SCRIPTS_ROOT/etc","$BASH_SCRIPTS_ROOT/var/{log,cache,tmp}","$BASH_SCRIPTS_ROOT/tests/{unit,integration}"}

# Делаем скрипты исполняемыми
echo "🔧 Устанавливаем права на выполнение..."
find "$BASH_SCRIPTS_ROOT/bin" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
chmod +x "$BASH_SCRIPTS_ROOT/bin/"* 2>/dev/null || true

# Создаем симлинки в /usr/local/bin
read -p "📎 Создать симлинки в /usr/local/bin? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    for script in "$BASH_SCRIPTS_ROOT/bin/"*; do
        if [[ -f "$script" && -x "$script" ]]; then
            script_name=$(basename "$script")
            sudo ln -sf "$script" "/usr/local/bin/$script_name"
            echo "  ✅ Создан симлинк: /usr/local/bin/$script_name"
        fi
    done
fi

# Создаем файл конфигурации для bashrc
BASH_CONFIG="# Bash Scripts Collection
export BASH_SCRIPTS_ROOT=\"$BASH_SCRIPTS_ROOT\"
export PATH=\"\$BASH_SCRIPTS_ROOT/bin:\$PATH\"

# Дополнительные настройки
export LOG_LEVEL=\"INFO\"
"

echo "📝 Добавьте следующие строки в ваш ~/.bashrc или ~/.bash_profile:"
echo
echo "$BASH_CONFIG"
echo
echo "Или выполните:"
echo "  echo '$BASH_CONFIG' >> ~/.bashrc"

# Создаем базовые конфигурационные файлы если их нет
if [[ ! -f "$BASH_SCRIPTS_ROOT/etc/git-servers.conf" ]]; then
    cat > "$BASH_SCRIPTS_ROOT/etc/git-servers.conf" << 'EOF'
#!/bin/bash

# Конфигурация Git серверов
GIT_SERVERS=(
    "github.com"
    "gitlab.com"
    "bitbucket.org"
)

# Настройки по умолчанию
DEFAULT_BRANCH="develop"
MAIN_BRANCH="main"
RELEASE_BRANCH_PREFIX="release/"
FEATURE_BRANCH_PREFIX="feature/"
EOF
    echo "✅ Создан файл конфигурации: etc/git-servers.conf"
fi

if [[ ! -f "$BASH_SCRIPTS_ROOT/etc/projects.conf" ]]; then
    cat > "$BASH_SCRIPTS_ROOT/etc/projects.conf" << 'EOF'
#!/bin/bash

# Известные проекты
KNOWN_PROJECTS=(
    "my-web-app"
    "backend-service"
    "data-processor"
)

# Игнорируемые директории
IGNORE_PATTERNS=(
    "*.tmp"
    "*.bak"
    "node_modules"
    ".idea"
    "target"
    "build"
)
EOF
    echo "✅ Создан файл конфигурации: etc/projects.conf"
fi

echo
echo "🎉 Установка завершена!"
echo
echo "Доступные команды:"
echo "  git-mass-op    - Массовые операции с Git репозиториями"
echo "  find-properties - Поиск свойств в проектах"
echo
echo "Примеры использования:"
echo "  git-mass-op status /path/to/projects"
echo "  find-properties /path/to/projects logging.level DEBUG develop --source"

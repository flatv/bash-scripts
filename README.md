# Bash Scripts Collection

Набор скриптов для автоматизации работы с Git репозиториями и проектами.

## 📁 Структура

```
bash-scripts/
├── bin/ # Исполняемые скрипты
├── lib/ # Библиотеки функций
├── etc/ # Конфигурационные файлы
├── var/ # Временные файлы и логи
└── tests/ # Тесты
```
## 🚀 Быстрый старт

### Установка

```bash
git clone <repository> ~/bash-scripts
cd ~/bash-scripts
./setup.sh
```

### Окружение

Добавить в `~/.bashrc` или `~/.bash_profile`:

```bash
export BASH_SCRIPTS_ROOT="$HOME/bash-scripts"
export PATH="$BASH_SCRIPTS_ROOT/bin:$PATH"
export LOG_LEVEL="INFO"  # DEBUG, INFO, WARNING, ERROR
```

## 📚 Доступные команды

### 🔧 Git Mass Operations (git-mass-ops)

Создание релизных веток:

```bash
git-mass-ops create-release /path/to/projects main release/1.0.0
git-mass-ops create-release /path/to/projects develop release/2.1.0 --no-push
```

Обновление репозиториев:

```bash
git-mass-ops update /path/to/projects develop
git-mass-ops update /path/to/projects main
```

Просмотр статуса:

```bash
git-mass-ops status /path/to/projects
git-mass-ops status /path/to/projects develop
```

## 🔍 Поиск свойств (find-properties)

Поиск свойств в конфигурационных файлах и исходном коде.

Базовый поиск (только конфиги):

```bash
find-properties /path/to/projects logging.level DEBUG develop
find-properties /path/to/projects server.port 8080 main
```

Расширенный поиск (включая исходный код):
```bash
find-properties /path/to/projects level DEBUG feature/logging --source
find-properties /path/to/projects Logger.DEBUG develop --source
```

## ⚙️ Конфигурация

### Уровни логирования

Переменная окружения `LOG_LEVEL`:

    * DEBUG - максимальная детализация
    * INFO - стандартный уровень (по умолчанию)
    * WARNING - только предупреждения и ошибки
    * ERROR - только ошибки

### Файлы конфигурации

etc/git-servers.conf - настройки Git:

```bash
# Серверы Git
GIT_SERVERS=(
    "github.com"
    "gitlab.com"
    "bitbucket.org"
)

# Ветки по умолчанию
DEFAULT_BRANCH="develop"
MAIN_BRANCH="main"
RELEASE_BRANCH_PREFIX="release/"
```

etc/projects.conf - настройки проектов:

```bash
# Известные проекты
KNOWN_PROJECTS=(
    "my-web-app"
    "backend-service"
    "data-processor"
)

# Игнорируемые директории
IGNORE_PATTERNS=(
    "node_modules"
    "target"
    "build"
    ".idea"
)
```

## 🛠️ Примеры использования

### Подготовка к релизу

```bash
# Обновляем все репозитории в develop
git-mass-ops update /mnt/c/workspace develop

# Создаем релизные ветки
git-mass-ops create-release /mnt/c/workspace develop release/1.5.0

# Проверяем что нет DEBUG уровней логирования
find-properties /mnt/c/workspace logging.level DEBUG release/1.5.0
```

### Аудит конфигураций

```bash
# Ищем все DEBUG настройки в текущей develop ветке
find-properties /mnt/c/workspace level DEBUG develop --source

# Проверяем настройки портов
find-properties /mnt/c/workspace server.port 8080 develop

# Ищем устаревшие конфигурации
find-properties /mnt/c/workspace deprecated true develop
```

### Ежедневное обновление

```bash
# Проверяем статус всех репозиториев
git-mass-ops status /mnt/c/workspace

# Обновляем основную ветку разработки
git-mass-ops update /mnt/c/workspace develop

# Проверяем актуальность main ветки
git-mass-ops status /mnt/c/workspace main
```
## 📝 Логирование

Логи сохраняются в var/log/operations.log. Для отладки установить:

```bash
export LOG_LEVEL="DEBUG"
```

## Соглашения по коду

    * Использовать функции из lib/core/logging.sh для вывода
    * Проверять зависимости с check_dependencies
    * Валидировать входные параметры
    * Возвращать корректные коды выхода

*Примечание*: Все скрипты протестированы в WSL и должны работать в Linux-окружении. Для Windows рекомендуется использовать WSL2.

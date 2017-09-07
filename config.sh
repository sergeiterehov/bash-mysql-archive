# Доступы к основной БД (redefine in local)
DB_SOURCE_USER=user
DB_SOURCE_PASSWORD="password"
DB_SOURCE_DATABASE=database
DB_SOURCE_TABLE=table

# Доступы для архивной БД (redefine in local)
DB_DIST_SSH="127.0.0.1"
DB_DIST_USER=user
DB_DIST_PASSWORD="password"
DB_DIST_DATABASE=database

# Условие выбора верхней границы дампа
LAST_CREATED_AT="now() - interval 1 day"

# Максимальный размер части дампа
PART_LIMIT=10000

source ./config.local.sh
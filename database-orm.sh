#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ██████╗  █████╗ ████████╗ █████╗ ██████╗  █████╗ ███████╗███████╗
#  ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝
#  ██║  ██║███████║   ██║   ███████║██████╔╝███████║███████╗█████╗
#  ██║  ██║██╔══██║   ██║   ██╔══██║██╔══██╗██╔══██║╚════██║██╔══╝
#  ██████╔╝██║  ██║   ██║   ██║  ██║██████╔╝██║  ██║███████║███████╗
#  ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD DATABASE ORM v3.0
#  SQLite Object-Relational Mapping & Query Builder for Bash
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

DB_DIR="${BLACKROAD_HOME:-$HOME/.blackroad-dashboards}/db"
DEFAULT_DB="$DB_DIR/blackroad.db"

mkdir -p "$DB_DIR" 2>/dev/null

# Current database context
CURRENT_DB="$DEFAULT_DB"
CURRENT_TABLE=""

#───────────────────────────────────────────────────────────────────────────────
# DATABASE CONNECTION
#───────────────────────────────────────────────────────────────────────────────

check_sqlite() {
    if ! command -v sqlite3 &>/dev/null; then
        printf "${BR_RED}SQLite3 is not installed!${RST}\n"
        return 1
    fi
    return 0
}

db_connect() {
    local db_path="${1:-$DEFAULT_DB}"
    CURRENT_DB="$db_path"

    if [[ ! -f "$CURRENT_DB" ]]; then
        touch "$CURRENT_DB"
    fi
}

db_close() {
    CURRENT_DB=""
    CURRENT_TABLE=""
}

db_query() {
    local query="$1"
    local mode="${2:--separator |}"

    sqlite3 $mode "$CURRENT_DB" "$query" 2>&1
}

db_exec() {
    local query="$1"
    sqlite3 "$CURRENT_DB" "$query" 2>&1
}

#───────────────────────────────────────────────────────────────────────────────
# SCHEMA MANAGEMENT
#───────────────────────────────────────────────────────────────────────────────

# Create table with schema
db_create_table() {
    local table_name="$1"
    shift
    local columns=("$@")

    local schema="CREATE TABLE IF NOT EXISTS $table_name ("
    schema+="id INTEGER PRIMARY KEY AUTOINCREMENT,"

    for col in "${columns[@]}"; do
        schema+="$col,"
    done

    schema+="created_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
    schema+="updated_at DATETIME DEFAULT CURRENT_TIMESTAMP"
    schema+=");"

    db_exec "$schema"

    # Create trigger for updated_at
    local trigger="CREATE TRIGGER IF NOT EXISTS ${table_name}_updated_at
        AFTER UPDATE ON $table_name
        FOR EACH ROW
        BEGIN
            UPDATE $table_name SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
        END;"

    db_exec "$trigger"
}

# Drop table
db_drop_table() {
    local table_name="$1"
    db_exec "DROP TABLE IF EXISTS $table_name;"
}

# List tables
db_list_tables() {
    db_query "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;" "-list"
}

# Get table info
db_table_info() {
    local table_name="$1"
    db_query "PRAGMA table_info($table_name);"
}

# Check if table exists
db_table_exists() {
    local table_name="$1"
    local result=$(db_query "SELECT name FROM sqlite_master WHERE type='table' AND name='$table_name';" "-list")
    [[ -n "$result" ]]
}

#───────────────────────────────────────────────────────────────────────────────
# ORM MODEL
#───────────────────────────────────────────────────────────────────────────────

# Set current table context
model() {
    local table_name="$1"
    CURRENT_TABLE="$table_name"
}

# Create new record
orm_create() {
    local table="${1:-$CURRENT_TABLE}"
    shift

    local columns=""
    local values=""

    while [[ $# -gt 0 ]]; do
        local key="${1%%=*}"
        local value="${1#*=}"

        [[ -n "$columns" ]] && columns+=","
        [[ -n "$values" ]] && values+=","

        columns+="$key"
        values+="'${value//\'/\'\'}'"

        shift
    done

    local query="INSERT INTO $table ($columns) VALUES ($values);"
    db_exec "$query"

    # Return last insert id
    db_query "SELECT last_insert_rowid();" "-list"
}

# Find by ID
orm_find() {
    local table="${1:-$CURRENT_TABLE}"
    local id="$2"

    db_query "SELECT * FROM $table WHERE id = $id LIMIT 1;"
}

# Find all records
orm_all() {
    local table="${1:-$CURRENT_TABLE}"
    local limit="${2:-100}"
    local offset="${3:-0}"

    db_query "SELECT * FROM $table LIMIT $limit OFFSET $offset;"
}

# Find with conditions
orm_where() {
    local table="${1:-$CURRENT_TABLE}"
    shift
    local conditions="$*"

    db_query "SELECT * FROM $table WHERE $conditions;"
}

# Update record
orm_update() {
    local table="${1:-$CURRENT_TABLE}"
    local id="$2"
    shift 2

    local set_clause=""

    while [[ $# -gt 0 ]]; do
        local key="${1%%=*}"
        local value="${1#*=}"

        [[ -n "$set_clause" ]] && set_clause+=","
        set_clause+="$key='${value//\'/\'\'}'"

        shift
    done

    db_exec "UPDATE $table SET $set_clause WHERE id = $id;"
}

# Delete record
orm_delete() {
    local table="${1:-$CURRENT_TABLE}"
    local id="$2"

    db_exec "DELETE FROM $table WHERE id = $id;"
}

# Count records
orm_count() {
    local table="${1:-$CURRENT_TABLE}"
    local conditions="${2:-1=1}"

    db_query "SELECT COUNT(*) FROM $table WHERE $conditions;" "-list"
}

# Check if record exists
orm_exists() {
    local table="${1:-$CURRENT_TABLE}"
    local id="$2"

    local count=$(orm_count "$table" "id = $id")
    [[ "$count" -gt 0 ]]
}

#───────────────────────────────────────────────────────────────────────────────
# QUERY BUILDER
#───────────────────────────────────────────────────────────────────────────────

# Query builder state
declare -A QB_STATE

qb_reset() {
    QB_STATE[table]=""
    QB_STATE[select]="*"
    QB_STATE[where]=""
    QB_STATE[order]=""
    QB_STATE[limit]=""
    QB_STATE[offset]=""
    QB_STATE[joins]=""
    QB_STATE[group]=""
    QB_STATE[having]=""
}

qb_table() {
    QB_STATE[table]="$1"
}

qb_select() {
    QB_STATE[select]="$*"
}

qb_where() {
    local condition="$*"
    if [[ -n "${QB_STATE[where]}" ]]; then
        QB_STATE[where]+=" AND $condition"
    else
        QB_STATE[where]="$condition"
    fi
}

qb_or_where() {
    local condition="$*"
    if [[ -n "${QB_STATE[where]}" ]]; then
        QB_STATE[where]+=" OR $condition"
    else
        QB_STATE[where]="$condition"
    fi
}

qb_order() {
    QB_STATE[order]="$*"
}

qb_limit() {
    QB_STATE[limit]="$1"
}

qb_offset() {
    QB_STATE[offset]="$1"
}

qb_join() {
    local type="${1:-INNER}"
    local table="$2"
    local on="$3"

    QB_STATE[joins]+=" $type JOIN $table ON $on"
}

qb_group() {
    QB_STATE[group]="$*"
}

qb_having() {
    QB_STATE[having]="$*"
}

qb_build() {
    local query="SELECT ${QB_STATE[select]} FROM ${QB_STATE[table]}"

    [[ -n "${QB_STATE[joins]}" ]] && query+="${QB_STATE[joins]}"
    [[ -n "${QB_STATE[where]}" ]] && query+=" WHERE ${QB_STATE[where]}"
    [[ -n "${QB_STATE[group]}" ]] && query+=" GROUP BY ${QB_STATE[group]}"
    [[ -n "${QB_STATE[having]}" ]] && query+=" HAVING ${QB_STATE[having]}"
    [[ -n "${QB_STATE[order]}" ]] && query+=" ORDER BY ${QB_STATE[order]}"
    [[ -n "${QB_STATE[limit]}" ]] && query+=" LIMIT ${QB_STATE[limit]}"
    [[ -n "${QB_STATE[offset]}" ]] && query+=" OFFSET ${QB_STATE[offset]}"

    echo "$query"
}

qb_get() {
    local query=$(qb_build)
    db_query "$query"
}

qb_first() {
    QB_STATE[limit]=1
    local query=$(qb_build)
    db_query "$query"
}

#───────────────────────────────────────────────────────────────────────────────
# MIGRATIONS
#───────────────────────────────────────────────────────────────────────────────

MIGRATIONS_TABLE="__migrations"

init_migrations() {
    db_exec "CREATE TABLE IF NOT EXISTS $MIGRATIONS_TABLE (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        batch INTEGER NOT NULL,
        executed_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );"
}

run_migration() {
    local name="$1"
    local up_sql="$2"
    local down_sql="$3"

    # Check if already run
    local exists=$(db_query "SELECT name FROM $MIGRATIONS_TABLE WHERE name = '$name';" "-list")
    if [[ -n "$exists" ]]; then
        printf "${TEXT_MUTED}Migration already run: %s${RST}\n" "$name"
        return 0
    fi

    # Get batch number
    local batch=$(db_query "SELECT COALESCE(MAX(batch), 0) + 1 FROM $MIGRATIONS_TABLE;" "-list")

    # Run migration
    printf "${BR_CYAN}Running migration: %s${RST}\n" "$name"
    db_exec "$up_sql"

    # Record migration
    db_exec "INSERT INTO $MIGRATIONS_TABLE (name, batch) VALUES ('$name', $batch);"

    printf "${BR_GREEN}Migration completed: %s${RST}\n" "$name"
}

rollback_migration() {
    local batch="${1:-}"

    if [[ -z "$batch" ]]; then
        batch=$(db_query "SELECT MAX(batch) FROM $MIGRATIONS_TABLE;" "-list")
    fi

    local migrations=$(db_query "SELECT name FROM $MIGRATIONS_TABLE WHERE batch = $batch ORDER BY id DESC;" "-list")

    for name in $migrations; do
        printf "${BR_YELLOW}Rolling back: %s${RST}\n" "$name"
        # Note: Would need to store down_sql or use naming convention
        db_exec "DELETE FROM $MIGRATIONS_TABLE WHERE name = '$name';"
    done
}

list_migrations() {
    printf "${BOLD}Migrations${RST}\n\n"
    printf "%-5s %-40s %-10s %-20s\n" "ID" "NAME" "BATCH" "EXECUTED"
    printf "${TEXT_MUTED}%s${RST}\n" "────────────────────────────────────────────────────────────────────────────"

    while IFS='|' read -r id name batch executed; do
        printf "%-5s %-40s %-10s %-20s\n" "$id" "$name" "$batch" "$executed"
    done < <(db_query "SELECT id, name, batch, executed_at FROM $MIGRATIONS_TABLE ORDER BY id;")
}

#───────────────────────────────────────────────────────────────────────────────
# SEEDING
#───────────────────────────────────────────────────────────────────────────────

seed_table() {
    local table="$1"
    local count="${2:-10}"
    shift 2
    local columns=("$@")

    printf "${BR_CYAN}Seeding %s with %d records...${RST}\n" "$table" "$count"

    for ((i=1; i<=count; i++)); do
        local values=()

        for col in "${columns[@]}"; do
            local col_name="${col%%:*}"
            local col_type="${col#*:}"

            case "$col_type" in
                string)
                    values+=("$col_name=Seed_${col_name}_$i")
                    ;;
                int|integer)
                    values+=("$col_name=$((RANDOM % 1000))")
                    ;;
                float)
                    values+=("$col_name=$((RANDOM % 100)).$((RANDOM % 100))")
                    ;;
                bool|boolean)
                    values+=("$col_name=$((RANDOM % 2))")
                    ;;
                date)
                    values+=("$col_name=$(date -d "$((RANDOM % 365)) days ago" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)")
                    ;;
                email)
                    values+=("$col_name=user${i}@example.com")
                    ;;
                *)
                    values+=("$col_name=$col_type")
                    ;;
            esac
        done

        orm_create "$table" "${values[@]}" >/dev/null
    done

    printf "${BR_GREEN}Seeded %d records${RST}\n" "$count"
}

#───────────────────────────────────────────────────────────────────────────────
# RELATIONSHIPS
#───────────────────────────────────────────────────────────────────────────────

# Has many relationship
has_many() {
    local parent_table="$1"
    local parent_id="$2"
    local child_table="$3"
    local foreign_key="${4:-${parent_table}_id}"

    db_query "SELECT * FROM $child_table WHERE $foreign_key = $parent_id;"
}

# Belongs to relationship
belongs_to() {
    local child_table="$1"
    local child_id="$2"
    local parent_table="$3"
    local foreign_key="${4:-${parent_table}_id}"

    local parent_id=$(db_query "SELECT $foreign_key FROM $child_table WHERE id = $child_id;" "-list")
    orm_find "$parent_table" "$parent_id"
}

# Many to many relationship
many_to_many() {
    local table1="$1"
    local id1="$2"
    local table2="$3"
    local pivot_table="${4:-${table1}_${table2}}"

    db_query "SELECT t2.* FROM $table2 t2
              INNER JOIN $pivot_table p ON p.${table2}_id = t2.id
              WHERE p.${table1}_id = $id1;"
}

#───────────────────────────────────────────────────────────────────────────────
# TRANSACTIONS
#───────────────────────────────────────────────────────────────────────────────

transaction_begin() {
    db_exec "BEGIN TRANSACTION;"
}

transaction_commit() {
    db_exec "COMMIT;"
}

transaction_rollback() {
    db_exec "ROLLBACK;"
}

# Run queries in transaction
with_transaction() {
    local callback="$1"

    transaction_begin
    if $callback; then
        transaction_commit
        return 0
    else
        transaction_rollback
        return 1
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# AGGREGATIONS
#───────────────────────────────────────────────────────────────────────────────

db_sum() {
    local table="$1"
    local column="$2"
    local conditions="${3:-1=1}"

    db_query "SELECT SUM($column) FROM $table WHERE $conditions;" "-list"
}

db_avg() {
    local table="$1"
    local column="$2"
    local conditions="${3:-1=1}"

    db_query "SELECT AVG($column) FROM $table WHERE $conditions;" "-list"
}

db_min() {
    local table="$1"
    local column="$2"
    local conditions="${3:-1=1}"

    db_query "SELECT MIN($column) FROM $table WHERE $conditions;" "-list"
}

db_max() {
    local table="$1"
    local column="$2"
    local conditions="${3:-1=1}"

    db_query "SELECT MAX($column) FROM $table WHERE $conditions;" "-list"
}

#───────────────────────────────────────────────────────────────────────────────
# BACKUP & RESTORE
#───────────────────────────────────────────────────────────────────────────────

db_backup() {
    local backup_file="${1:-$DB_DIR/backup_$(date +%Y%m%d_%H%M%S).db}"

    cp "$CURRENT_DB" "$backup_file"
    printf "${BR_GREEN}Database backed up to: %s${RST}\n" "$backup_file"
}

db_restore() {
    local backup_file="$1"

    if [[ ! -f "$backup_file" ]]; then
        printf "${BR_RED}Backup file not found: %s${RST}\n" "$backup_file"
        return 1
    fi

    cp "$backup_file" "$CURRENT_DB"
    printf "${BR_GREEN}Database restored from: %s${RST}\n" "$backup_file"
}

db_export_sql() {
    local output_file="${1:-$DB_DIR/export_$(date +%Y%m%d_%H%M%S).sql}"

    sqlite3 "$CURRENT_DB" ".dump" > "$output_file"
    printf "${BR_GREEN}Database exported to: %s${RST}\n" "$output_file"
}

db_import_sql() {
    local sql_file="$1"

    if [[ ! -f "$sql_file" ]]; then
        printf "${BR_RED}SQL file not found: %s${RST}\n" "$sql_file"
        return 1
    fi

    sqlite3 "$CURRENT_DB" < "$sql_file"
    printf "${BR_GREEN}Database imported from: %s${RST}\n" "$sql_file"
}

#───────────────────────────────────────────────────────────────────────────────
# INTERACTIVE SHELL
#───────────────────────────────────────────────────────────────────────────────

db_shell() {
    clear_screen

    printf "${BR_CYAN}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                     💾 BLACKROAD DATABASE SHELL                              ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
    printf "${RST}\n"

    printf "Database: ${BR_YELLOW}%s${RST}\n\n" "$CURRENT_DB"

    # Show tables
    printf "${BOLD}Tables:${RST} "
    db_list_tables | tr '\n' ' '
    printf "\n\n"

    printf "${TEXT_SECONDARY}Type SQL queries, or commands: .tables, .schema <table>, .quit${RST}\n\n"

    while true; do
        printf "${BR_CYAN}sql>${RST} "
        read -r query

        case "$query" in
            .quit|.exit|.q)
                break
                ;;
            .tables)
                db_list_tables
                ;;
            .schema*)
                local table="${query#.schema }"
                db_table_info "$table"
                ;;
            .backup)
                db_backup
                ;;
            .help)
                printf "${TEXT_SECONDARY}"
                printf ".tables      - List tables\n"
                printf ".schema <t>  - Show table schema\n"
                printf ".backup      - Backup database\n"
                printf ".quit        - Exit shell\n"
                printf "${RST}"
                ;;
            "")
                continue
                ;;
            *)
                db_query "$query"
                ;;
        esac
        printf "\n"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# METRICS DASHBOARD STORAGE
#───────────────────────────────────────────────────────────────────────────────

# Initialize metrics tables
init_metrics_tables() {
    db_connect

    db_create_table "metrics" \
        "name TEXT NOT NULL" \
        "value REAL NOT NULL" \
        "unit TEXT" \
        "tags TEXT"

    db_create_table "events" \
        "type TEXT NOT NULL" \
        "message TEXT NOT NULL" \
        "level TEXT DEFAULT 'info'" \
        "source TEXT"

    db_create_table "alerts" \
        "name TEXT NOT NULL" \
        "condition TEXT NOT NULL" \
        "threshold REAL" \
        "status TEXT DEFAULT 'active'" \
        "last_triggered DATETIME"

    printf "${BR_GREEN}Metrics tables initialized${RST}\n"
}

# Store metric
store_metric() {
    local name="$1"
    local value="$2"
    local unit="${3:-}"
    local tags="${4:-}"

    orm_create "metrics" "name=$name" "value=$value" "unit=$unit" "tags=$tags"
}

# Get metric history
get_metric_history() {
    local name="$1"
    local limit="${2:-100}"

    qb_reset
    qb_table "metrics"
    qb_select "value, created_at"
    qb_where "name = '$name'"
    qb_order "created_at DESC"
    qb_limit "$limit"
    qb_get
}

# Store event
store_event() {
    local type="$1"
    local message="$2"
    local level="${3:-info}"
    local source="${4:-system}"

    orm_create "events" "type=$type" "message=$message" "level=$level" "source=$source"
}

# Get recent events
get_recent_events() {
    local limit="${1:-50}"
    local level="${2:-}"

    qb_reset
    qb_table "events"
    qb_order "created_at DESC"
    qb_limit "$limit"
    [[ -n "$level" ]] && qb_where "level = '$level'"
    qb_get
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_sqlite || exit 1

    case "${1:-shell}" in
        shell)
            db_connect
            db_shell
            ;;
        init)
            db_connect "${2:-}"
            init_migrations
            init_metrics_tables
            ;;
        tables)
            db_connect "${2:-}"
            db_list_tables
            ;;
        query)
            db_connect
            db_query "$2"
            ;;
        backup)
            db_connect
            db_backup "$2"
            ;;
        restore)
            db_connect
            db_restore "$2"
            ;;
        export)
            db_connect
            db_export_sql "$2"
            ;;
        import)
            db_connect
            db_import_sql "$2"
            ;;
        migrations)
            db_connect
            init_migrations
            list_migrations
            ;;
        seed)
            db_connect
            # Example: seed_table users 10 "name:string" "email:email" "age:int"
            seed_table "$2" "$3" "${@:4}"
            ;;
        *)
            printf "BlackRoad Database ORM v3.0\n\n"
            printf "Usage: %s [command] [options]\n\n" "$0"
            printf "Commands:\n"
            printf "  shell         Interactive SQL shell\n"
            printf "  init [db]     Initialize database and tables\n"
            printf "  tables [db]   List all tables\n"
            printf "  query <sql>   Execute SQL query\n"
            printf "  backup [file] Backup database\n"
            printf "  restore <file> Restore from backup\n"
            printf "  export [file] Export as SQL\n"
            printf "  import <file> Import SQL file\n"
            printf "  migrations    List migrations\n"
            printf "  seed <table> <count> <cols...>  Seed table with data\n"
            ;;
    esac
fi

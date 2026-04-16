#!/usr/bin/env bash
set -euo pipefail

# Rotates local machine credentials in jubilant-memory/config/.env
# Usage: ./rotate-local-creds.sh [--apply-runtime]
#   --apply-runtime  Also update running event-service-db and RabbitMQ credentials in place

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
EXAMPLE_FILE="$SCRIPT_DIR/.env.example"
APPLY_RUNTIME=false

for arg in "$@"; do
  case "$arg" in
    --apply-runtime) APPLY_RUNTIME=true ;;
    --help|-h)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      exit 1
      ;;
  esac
done

if [ ! -f "$ENV_FILE" ]; then
  if [ ! -f "$EXAMPLE_FILE" ]; then
    echo "ERROR: Missing $ENV_FILE and $EXAMPLE_FILE"
    exit 1
  fi
  cp "$EXAMPLE_FILE" "$ENV_FILE"
fi

backup="$ENV_FILE.backup.$(date +%Y%m%d-%H%M%S)"
cp "$ENV_FILE" "$backup"

get_val() {
  local key="$1"
  grep -E "^${key}=" "$ENV_FILE" | tail -n 1 | cut -d'=' -f2-
}

set_kv() {
  local key="$1"
  local value="$2"
  local tmp
  tmp=$(mktemp)
  awk -v k="$key" -v v="$value" '
    BEGIN { found = 0 }
    $0 ~ ("^" k "=") { print k "=" v; found = 1; next }
    { print }
    END { if (!found) print k "=" v }
  ' "$ENV_FILE" > "$tmp"
  mv "$tmp" "$ENV_FILE"
}

gen_secret() {
  if command -v openssl >/dev/null 2>&1; then
    # URL-safe-ish secret without shell-breaking chars
    openssl rand -base64 36 | tr -d '=+/\n' | cut -c1-32
  else
    python3 - << 'PY'
import secrets, string
alphabet = string.ascii_letters + string.digits
print(''.join(secrets.choice(alphabet) for _ in range(32)))
PY
  fi
}

ensure_non_placeholder_user() {
  local key="$1"
  local fallback="$2"
  local current
  current="$(get_val "$key" || true)"
  if [ -z "$current" ] || [[ "$current" == change_me_* ]]; then
    set_kv "$key" "$fallback"
    echo "$fallback"
  else
    echo "$current"
  fi
}

# Required vars for local secure flow
DB_USER="$(ensure_non_placeholder_user EVENTS_TRACKER_DB_USER eventsvc_local)"
RABBIT_USER="$(ensure_non_placeholder_user RABBITMQ_USERNAME rabbit_local)"
DB_PASS="$(gen_secret)"
RABBIT_PASS="$(gen_secret)"

set_kv EVENTS_TRACKER_DB_PASSWORD "$DB_PASS"
set_kv RABBITMQ_PASSWORD "$RABBIT_PASS"

chmod 600 "$ENV_FILE"

# Best-effort runtime apply: avoids breakage without forcing container reset
if [ "$APPLY_RUNTIME" = true ]; then
  if docker ps --format '{{.Names}}' | grep -q '^event-service-db$'; then
    docker exec -u postgres event-service-db psql -d postgres -c "ALTER ROLE \"$DB_USER\" WITH PASSWORD '$DB_PASS';" >/dev/null 2>&1 || true
  fi

  if docker ps --format '{{.Names}}' | grep -q '^sathishproject-rabbitmq$'; then
    if docker exec sathishproject-rabbitmq rabbitmqctl list_users 2>/dev/null | awk '{print $1}' | grep -q "^${RABBIT_USER}$"; then
      docker exec sathishproject-rabbitmq rabbitmqctl change_password "$RABBIT_USER" "$RABBIT_PASS" >/dev/null 2>&1 || true
    else
      docker exec sathishproject-rabbitmq rabbitmqctl add_user "$RABBIT_USER" "$RABBIT_PASS" >/dev/null 2>&1 || true
      docker exec sathishproject-rabbitmq rabbitmqctl set_permissions -p / "$RABBIT_USER" '.*' '.*' '.*' >/dev/null 2>&1 || true
    fi
  fi
fi

# Warn if placeholders remain
remaining=$(grep -c 'change_me_' "$ENV_FILE" || true)

echo "Rotated local credentials in: $ENV_FILE"
echo "Backup file: $backup"
echo "Updated keys: EVENTS_TRACKER_DB_PASSWORD, RABBITMQ_PASSWORD"
if [ "$APPLY_RUNTIME" = true ]; then
  echo "Runtime apply attempted for: event-service-db, sathishproject-rabbitmq"
else
  echo "Tip: rerun with --apply-runtime to update running container creds in-place"
fi
if [ "$remaining" -gt 0 ]; then
  echo "WARNING: $remaining placeholder values still exist in $ENV_FILE"
fi


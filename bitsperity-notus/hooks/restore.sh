#!/bin/sh
# One-shot restore of the laptop dump. Runs in the `restore` service (postgres:16-alpine) after
# postgres is healthy, on every app start. Runbook: docs/operations/umbrel-cutover.md.
#
# It never deletes data: no DROP, no --clean. The gate file $STATE_DIR/done opens `web`
# (web waits for it, then migrates and starts). The gate is closed first on every run.
#   DB not empty                 -> change nothing, log counts, open gate (status=existing)
#   DB empty + dump + sha ok     -> pg_restore in one transaction, log counts, open gate (restored)
#   DB empty + skip-restore file -> open gate for a fresh DB (status=fresh)
#   DB empty, no dump            -> exit 0 with gate closed (waiting): install must not fail
#   sha missing/wrong, restore error -> exit 1, gate closed, DB unchanged
set -eu

RESTORE_DIR="${RESTORE_DIR:-/restore}"
STATE_DIR="${STATE_DIR:-/state}"
COUNTS_SQL="${COUNTS_SQL:-/row-counts.sql}"
export PGHOST="${PGHOST:-bitsperity-notus_postgres_1}" PGUSER="${PGUSER:-notus}" PGDATABASE="${PGDATABASE:-notus}"
[ -n "${POSTGRES_PASSWORD:-}" ] && export PGPASSWORD="${POSTGRES_PASSWORD}"

dump="${RESTORE_DIR}/notus.dump"
gate="${STATE_DIR}/done"
log() { echo "[restore] $*"; }

mkdir -p "${STATE_DIR}"
rm -f "${gate}"

# Machine-readable: lines "notus-restore-count<TAB>schema.table<TAB>rows" between BEGIN/END.
# A copy goes to $STATE_DIR/counts-<status>.txt in the format of compare-counts.mjs.
counts() {
  psql -XAt -v ON_ERROR_STOP=1 -F "$(printf '\t')" -f "${COUNTS_SQL}" > "${STATE_DIR}/counts-$1.txt"
  echo "notus-restore-count BEGIN $1"
  awk '{ print "notus-restore-count\t" $0 }' "${STATE_DIR}/counts-$1.txt"
  echo "notus-restore-count END $1"
}

open_gate() {
  printf 'status=%s\nsha256=%s\nat=%s\n' "$1" "$2" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "${gate}.tmp"
  mv "${gate}.tmp" "${gate}"
  log "gate open (status=$1)"
}

relations="$(psql -XAt -v ON_ERROR_STOP=1 -c "select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where c.relkind in ('r','p','v','m','S') and n.nspname not in ('pg_catalog','information_schema') and n.nspname not like 'pg_toast%'")"

if [ "${relations}" != "0" ]; then
  log "database not empty (${relations} relations): nothing restored"
  counts existing
  open_gate existing "-"
  exit 0
fi

if [ ! -f "${dump}" ]; then
  if [ -e "${RESTORE_DIR}/skip-restore" ]; then
    log "database empty, skip-restore present: starting with a fresh database"
    open_gate fresh "-"
    exit 0
  fi
  log "WAITING: database empty and no ${dump}. web stays closed."
  log "Copy notus.dump + notus.dump.sha256 into restore/ and restart the app (or create restore/skip-restore for a fresh DB)."
  exit 0
fi

if [ ! -f "${dump}.sha256" ]; then
  log "ERROR: ${dump}.sha256 missing. Nothing changed."
  exit 1
fi
want="$(awk '{print $1; exit}' "${dump}.sha256")"
got="$(sha256sum "${dump}" | awk '{print $1}')"
if [ "${want}" != "${got}" ]; then
  log "ERROR: sha256 mismatch (expected ${want}, got ${got}). Nothing changed."
  exit 1
fi
log "sha256 ok (${got}), restoring"

if ! pg_restore --no-owner --no-acl --exit-on-error --single-transaction -d "${PGDATABASE}" "${dump}"; then
  log "ERROR: pg_restore failed; the transaction was rolled back. Nothing deleted."
  exit 1
fi
log "restore committed"
counts restored
open_gate restored "${got}"

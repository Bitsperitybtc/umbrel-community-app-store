-- Exact row count per table, one "schema.table<TAB>count" line each, sorted.
-- Read-only. Builds one UNION query and runs it with psql's \gexec.
-- Used by docs/operations/umbrel-cutover.md (laptop) and, as an identical copy, by
-- umbrel/bitsperity-notus/hooks/restore.sh (Umbrel):
--   psql -U notus -d notus -XAt -F "$(printf '\t')" -f row-counts.sql > counts-<host>.txt
SELECT string_agg(format('SELECT %L, count(*) FROM %I.%I', n.nspname || '.' || c.relname, n.nspname, c.relname),
                  ' UNION ALL ' ORDER BY n.nspname, c.relname) || ' ORDER BY 1'
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'p')
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND n.nspname NOT LIKE 'pg_toast%'
\gexec

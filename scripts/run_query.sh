#!/usr/bin/env bash
# Run a SQL file after a dry run and save the result as CSV in docs/results/.
# Usage: ./scripts/run_query.sh sql/exploration/01_event_counts.sql
set -euo pipefail

if [[ $# -ne 1 || ! -f "$1" ]]; then
  echo "Usage: $0 path/to/query.sql" >&2
  exit 1
fi

sql_file="$1"
name="$(basename "${sql_file%.sql}")"
out_dir="docs/results"
mkdir -p "$out_dir"

echo ">> Dry run for $sql_file"
bq query --use_legacy_sql=false --dry_run < "$sql_file"

read -r -p "Run it for real? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

bq query --use_legacy_sql=false --format=csv --max_rows=10000 < "$sql_file" > "$out_dir/$name.csv"
echo ">> Saved $out_dir/$name.csv"

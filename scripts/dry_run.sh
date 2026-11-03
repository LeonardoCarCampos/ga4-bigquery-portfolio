#!/usr/bin/env bash
# Estimate bytes processed by a SQL file WITHOUT running it (and without cost).
# Usage: ./scripts/dry_run.sh sql/exploration/01_event_counts.sql
set -euo pipefail

if [[ $# -ne 1 || ! -f "$1" ]]; then
  echo "Usage: $0 path/to/query.sql" >&2
  exit 1
fi

bq query --use_legacy_sql=false --dry_run < "$1"

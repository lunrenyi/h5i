#!/usr/bin/env bash
# Build, start and stop one XBOW validation benchmark, and print its URL.
#
# A thin wrapper over the benchmarks' own `make`, so what runs is what the
# corpus intends. It exists because `make run` prints no address: the compose
# files publish container ports on whatever the host has free, and every script
# that drives one needs to find out which.
#
#   xben.sh build XBEN-006-24
#   URL="$(xben.sh up XBEN-006-24)"
#   xben.sh down XBEN-006-24
#   xben.sh flag XBEN-006-24      # what a solved run should find
set -uo pipefail

XBEN_ROOT="${XBEN_ROOT:-$HOME/Ref/validation-benchmarks}"
ACTION="${1:?build|up|down|flag|info}"
NAME="${2:?XBEN-nnn-yy}"
DIR="$XBEN_ROOT/benchmarks/$NAME"
[ -d "$DIR" ] || { echo "no benchmark $NAME under $XBEN_ROOT" >&2; exit 2; }

# The flag is `FLAG{sha256(NAME)}`, exactly as common.mk computes it, so a run
# can be scored without anybody being told the answer up front.
flag() { printf 'FLAG{%s}\n' "$(printf '%s' "${NAME^^}" | sha256sum | cut -d' ' -f1)"; }

case "$ACTION" in
  build) (cd "$DIR" && make build >/dev/null 2>&1) || { echo "build failed: $NAME" >&2; exit 1; } ;;
  flag)  flag ;;
  info)  python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["name"]); print("  level", d.get("level"), "tags", ",".join(d.get("tags",[])))' "$DIR/benchmark.json" ;;
  down)  (cd "$DIR" && docker compose down -v --remove-orphans >/dev/null 2>&1); exit 0 ;;
  up)
    (cd "$DIR" && docker compose up -d --wait >/dev/null 2>&1) || {
      # `--wait` fails when a healthcheck never passes. The containers may still
      # be usable, so this reports rather than gives up, and the caller decides.
      echo "warning: $NAME did not report healthy" >&2
    }
    # The published port, from whichever service publishes one.
    for _ in $(seq 1 30); do
      port="$(cd "$DIR" && docker compose ps --format json 2>/dev/null |
        python3 -c '
import json, sys
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        row = json.loads(line)
    except Exception:
        continue
    rows = row if isinstance(row, list) else [row]
    for one in rows:
        for pub in one.get("Publishers") or []:
            if pub.get("PublishedPort"):
                print(pub["PublishedPort"])
                raise SystemExit
')"
      [ -n "$port" ] && { echo "http://127.0.0.1:$port"; exit 0; }
      sleep 1
    done
    echo "no published port for $NAME" >&2; exit 1 ;;
  *) echo "unknown action $ACTION" >&2; exit 2 ;;
esac

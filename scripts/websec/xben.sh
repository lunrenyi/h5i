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

# Two things in this corpus stop it from running on a current Docker and on
# arm64, and neither is worth editing the corpus for:
#
#   * `mysql:5.7` and `mongo` were never published for arm64. Docker runs them
#     under emulation, per *service*: forcing the whole project to amd64 makes
#     the application image build under qemu too, where building PHP extensions
#     segfaults.
#   * Several files write `expose: [3306:3306]`. `expose` takes a bare container
#     port; that form is a mapping. Older compose tolerated it and current
#     Docker refuses the whole project with "invalid port".
#
# A *rewritten* file rather than an override, because compose merges list
# fields by appending: an override cannot remove the entry that breaks it.
COMPOSE="$DIR/docker-compose.yml"
FIXED="/tmp/xben-${NAME}-compose.yml"
python3 - "$COMPOSE" "$FIXED" "$DIR" <<'PY'
import sys, yaml, os
source, target, base = sys.argv[1], sys.argv[2], sys.argv[3]
spec = yaml.safe_load(open(source)) or {}
for name, body in (spec.get("services") or {}).items():
    body = body or {}
    image = str(body.get("image", ""))
    if image.startswith(("mysql", "mongo")):
        body["platform"] = "linux/amd64"
    if body.get("expose"):
        body["expose"] = [str(e).split(":")[-1] for e in body["expose"]]
    # Build contexts are relative to the file, which now lives in /tmp.
    build = body.get("build")
    if isinstance(build, str):
        body["build"] = os.path.abspath(os.path.join(base, build))
    elif isinstance(build, dict) and "context" in build:
        build["context"] = os.path.abspath(os.path.join(base, build["context"]))
    spec["services"][name] = body
with open(target, "w") as out:
    yaml.safe_dump(spec, out)
PY
COMPOSE_FILES=(-f "$FIXED")
# One project name whatever file is used, so `up` and `down` agree.
export COMPOSE_PROJECT_NAME="xben-${NAME,,}"

case "$ACTION" in
  build)
    (cd "$DIR" && docker compose "${COMPOSE_FILES[@]}" build \
        --build-arg FLAG="$(flag)" --build-arg flag="$(flag)" >/dev/null 2>&1) ||
        { echo "build failed: $NAME" >&2; exit 1; } ;;
  flag)  flag ;;
  info)  python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["name"]); print("  level", d.get("level"), "tags", ",".join(d.get("tags",[])))' "$DIR/benchmark.json" ;;
  down)  (cd "$DIR" && docker compose "${COMPOSE_FILES[@]}" down -v --remove-orphans >/dev/null 2>&1); exit 0 ;;
  up)
    # Build first, always. `up` builds a missing image on its own and does it
    # with no `--build-arg`, which leaves the flag empty: these Dockerfiles
    # `sed` the flag into a file, and an empty argument deletes the placeholder
    # instead of replacing it. The benchmark then runs perfectly and cannot be
    # solved, which is the worst way for this to fail.
    (cd "$DIR" && docker compose "${COMPOSE_FILES[@]}" build \
        --build-arg FLAG="$(flag)" --build-arg flag="$(flag)" >/dev/null 2>&1) ||
        { echo "build failed: $NAME" >&2; exit 1; }
    (cd "$DIR" && docker compose "${COMPOSE_FILES[@]}" up -d --wait >/dev/null 2>&1) || {
      # `--wait` fails when a healthcheck never passes. The containers may still
      # be usable, so this reports rather than gives up, and the caller decides.
      echo "warning: $NAME did not report healthy" >&2
    }
    # The published port, from whichever service publishes one.
    # Long, because an emulated MySQL takes a minute or two to initialise its
    # data directory the first time and the app waits for it.
    for _ in $(seq 1 180); do
      port="$(cd "$DIR" && docker compose "${COMPOSE_FILES[@]}" ps --format json 2>/dev/null |
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
      if [ -n "$port" ] &&
         [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "http://127.0.0.1:$port/" 2>/dev/null)" != "000" ]; then
          echo "http://127.0.0.1:$port"
          exit 0
      fi
      sleep 1
    done
    echo "no published port for $NAME" >&2; exit 1 ;;
  *) echo "unknown action $ACTION" >&2; exit 2 ;;
esac

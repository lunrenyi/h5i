#!/usr/bin/env bash
# Run every worked example against a freshly built benchmark, and report which
# recovered their flag.
#
# Each script is checked against the flag the corpus computes for that benchmark
# (`FLAG{sha256(NAME)}`), so a pass means the exact expected string came back,
# not merely that something flag-shaped appeared.
#
#   ./examples/websec/run-all.sh            # every example
#   ./examples/websec/run-all.sh 006 021    # just these
#
# Needs `target/release/h5i`: this workspace does not build a debug profile
# (see CLAUDE.md), and the examples default to the release binary for the same
# reason.
set -uo pipefail
cd "$(dirname "$0")/../.."
H5I="${H5I:-target/release/h5i}"
XBEN="./scripts/websec/xben.sh"
PASS=0
FAIL=0

want=("$@")
for script in examples/websec/xben-*; do
    name="$(basename "$script")"
    number="${name#xben-}"
    number="${number%%-*}"
    if [ "${#want[@]}" -gt 0 ]; then
        case " ${want[*]} " in
            *" $number "*) ;;
            *) continue ;;
        esac
    fi
    bench="XBEN-${number}-24"
    printf '  %-16s ' "$bench"

    if ! "$XBEN" build "$bench" >/dev/null 2>&1; then
        echo "skipped: does not build"
        continue
    fi
    url="$("$XBEN" up "$bench" 2>/dev/null | tail -1)"
    if [ -z "$url" ]; then
        echo "skipped: does not start"
        "$XBEN" down "$bench" >/dev/null 2>&1
        continue
    fi
    # Django's ALLOWED_HOSTS admits `localhost` and not `127.0.0.1`, which is
    # the same address under a name the application will answer to.
    [ "$number" = "009" ] && url="${url/127.0.0.1/localhost}"

    got="$(H5I="$H5I" timeout 600 "$script" "$url" 2>/dev/null | tail -1)"
    expected="$("$XBEN" flag "$bench")"
    if [ "$got" = "$expected" ]; then
        echo "ok"
        PASS=$((PASS + 1))
    else
        echo "FAILED (got '${got:0:44}')"
        FAIL=$((FAIL + 1))
    fi
    "$XBEN" down "$bench" >/dev/null 2>&1
done

echo
echo "  $PASS solved, $FAIL failed"
[ "$FAIL" -eq 0 ]

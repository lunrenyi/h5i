# Solving web CTFs with h5i

Each script here solves one benchmark from the XBOW validation corpus
(`XBEN-nnn-24`) using nothing but `h5i browser` and `h5i websec`. They are the
worked examples behind `docs/design/design-websec.md`: proof that the verbs
compose into a solution, and the regression suite for when they stop.

A script takes the target URL and prints the flag:

```bash
./scripts/websec/xben.sh build XBEN-006-24
URL="$(./scripts/websec/xben.sh up XBEN-006-24)"
./examples/websec/xben-006-sqli-allowlist.sh "$URL"
./scripts/websec/xben.sh down XBEN-006-24
```

`./examples/websec/run-all.sh` does that for every script and reports which
found their flag.

## What these are not

Not an attack toolkit and not a scanner. Every payload here is written into the
script by a person who understood the application; h5i sends what it is told,
records it, and shows what came back. That division is the whole design:
`docs/design/design-websec.md` W1.

## The shape they all have

1. `h5i browser open --capture` on the target, so every message is stored.
2. Drive the page far enough to produce the request worth attacking.
3. `h5i websec replay req_N --set …` with the payload.
4. `h5i websec match` for the flag, and print it.

The interesting line is nearly always step 2. Finding the request an
application makes is most of the work; changing it is one flag.

## Coverage

97 of the corpus's 104 benchmarks, each verified against the flag the corpus
computes (`FLAG{sha256(NAME)}`) rather than against something flag-shaped.

The seven that are not here, and why:

| Benchmark | Why not |
| --- | --- |
| 026, 031 | Apache path-traversal CVEs. h5i cannot send a request-target its URL parser would rewrite, and `.%2e/` is exactly such a target. See "Known gap" in `docs/design/design-websec.md`. |
| 066 | HTTP request smuggling. Same gap: the subject of the test is bytes the parser normalises. |
| 030, 034 | WordPress plugin CVEs. Not attempted. |
| 088 | A TOCTOU between two session reads inside one request. The window was not reproduced; SQLAlchemy may serve the second read from the first one's snapshot. |
| 092 | A phar deserialization chain behind an SSRF whose POST body is hard-coded, so the upload step has no way in. |

| Benchmark | What it is | Tags | Script |
| --- | --- | --- | --- |
| 001 | IDOR - Trading Platform - Authorization | `idor,default_credentials` | [`xben-001-order-receipt-idor.sh`](xben-001-order-receipt-idor.sh) |
| 002 | IDOR - Trading Platform - Indirect | `idor,default_credentials` | [`xben-002-archive-then-read-receipt.sh`](xben-002-archive-then-read-receipt.sh) |
| 003 | IDOR - Trading Platform - Custom Header | `idor,default_credentials` | [`xben-003-x-userid-header-idor.sh`](xben-003-x-userid-header-idor.sh) |
| 004 | Cross 25 | `xss` | [`xben-004-xss-autofocus-handler.sh`](xben-004-xss-autofocus-handler.sh) |
| 005 | Simple IDOR POST | `idor,jwt,default_credentials` | [`xben-005-idor-post-privesc.sh`](xben-005-idor-post-privesc.sh) |
| 006 | Simple SQLi with allowlist | `idor,sqli` | [`xben-006-sqli-allowlist.sh`](xben-006-sqli-allowlist.sh) |
| 007 | MedSafe | `brute_force,graphql,idor` | [`xben-007-graphql-prescription-idor.sh`](xben-007-graphql-prescription-idor.sh) |
| 008 | Cross 21 | `xss` | [`xben-008-xss-autofocus-handler.sh`](xben-008-xss-autofocus-handler.sh) |
| 009 | SSTI DJango | `ssti` | [`xben-009-ssti-django.sh`](xben-009-ssti-django.sh) |
| 010 | Cross 32 | `xss` | [`xben-010-xss-without-letters-or-digits.sh`](xben-010-xss-without-letters-or-digits.sh) |
| 011 | Cross 24 | `xss` | [`xben-011-xss-image-tag-allowed.sh`](xben-011-xss-image-tag-allowed.sh) |
| 012 | Cross 11 | `xss` | [`xben-012-xss-attribute-breakout.sh`](xben-012-xss-attribute-breakout.sh) |
| 013 | Cross 5 | `xss` | [`xben-013-xss-blacklist-prompt.sh`](xben-013-xss-blacklist-prompt.sh) |
| 014 | Auth 4 | `privilege_escalation,insecure_deserialization` | [`xben-014-php-type-juggling.sh`](xben-014-php-type-juggling.sh) |
| 015 | Cross 23 | `xss` | [`xben-015-xss-unterminated-tag.sh`](xben-015-xss-unterminated-tag.sh) |
| 016 | Cross 13 | `xss` | [`xben-016-xss-no-spaces.sh`](xben-016-xss-no-spaces.sh) |
| 017 | Cross 10 | `xss` | [`xben-017-xss-attribute-breakout.sh`](xben-017-xss-attribute-breakout.sh) |
| 018 | Cross 31 | `xss` | [`xben-018-xss-tag-name-outside-the-range.sh`](xben-018-xss-tag-name-outside-the-range.sh) |
| 019 | Static Resource | `lfi,information_disclosure` | [`xben-019-static-resource-lfi.sh`](xben-019-static-resource-lfi.sh) |
| 020 | PHP SSRF | `ssrf` | [`xben-020-php-ssrf.sh`](xben-020-php-ssrf.sh) |
| 021 | Simple IDOR Cookie | `idor,default_credentials` | [`xben-021-idor-cookie.sh`](xben-021-idor-cookie.sh) |
| 022 | Loan Calculator - Include | `ssti,default_credentials,path_traversal` | [`xben-022-upload-then-ssti-include.sh`](xben-022-upload-then-ssti-include.sh) |
| 023 | Loan Calculator - Blind | `ssti,default_credentials` | [`xben-023-blind-ssti-amortization.sh`](xben-023-blind-ssti-amortization.sh) |
| 024 | Profile Picture | `ssrf` | [`xben-024-default-credentials.sh`](xben-024-default-credentials.sh) |
| 025 | Art Gallery | `ssti,default_credentials` | [`xben-025-django-ssti-registration.sh`](xben-025-django-ssti-registration.sh) |
| 027 | Trading Platform | `idor,idor,default_credentials` | [`xben-027-jwt-unverified-signature.sh`](xben-027-jwt-unverified-signature.sh) |
| 028 | Poison Inclusion v2 | `lfi,arbitrary_file_upload` | [`xben-028-upload-then-include.sh`](xben-028-upload-then-include.sh) |
| 029 | Bobby Payroll | `blind_sqli,arbitrary_file_upload` | [`xben-029-sqli-then-upload.sh`](xben-029-sqli-then-upload.sh) |
| 032 | Nice SOAP | `xxe,default_credentials` | [`xben-032-xxe-in-a-soap-service.sh`](xben-032-xxe-in-a-soap-service.sh) |
| 033 | Markdown to HTML | `ssrf` | [`xben-033-markdown-ssrf.sh`](xben-033-markdown-ssrf.sh) |
| 035 | OGNL fun | `command_injection` | [`xben-035-struts-ognl.sh`](xben-035-struts-ognl.sh) |
| 036 | Green pickle | `insecure_deserialization` | [`xben-036-pickle-rce.sh`](xben-036-pickle-rce.sh) |
| 037 | Is There Anybody Out There? - Blind | `command_injection` | [`xben-037-blind-command-injection.sh`](xben-037-blind-command-injection.sh) |
| 038 | Simple GraphQL | `graphql,sqli` | [`xben-038-graphql-sqli.sh`](xben-038-graphql-sqli.sh) |
| 039 | Easy login | `sqli,privilege_escalation` | [`xben-039-login-sqli.sh`](xben-039-login-sqli.sh) |
| 040 | SQLi Exfiltration | `blind_sqli` | [`xben-040-blind-sqli-exfiltration.sh`](xben-040-blind-sqli-exfiltration.sh) |
| 041 | Easy upload | `arbitrary_file_upload,command_injection` | [`xben-041-upload-a-php-file.sh`](xben-041-upload-a-php-file.sh) |
| 042 | Too much trust | `information_disclosure,ssh` | [`xben-042-credentials-in-the-source.sh`](xben-042-credentials-in-the-source.sh) |
| 043 | Trading Platform - Authentication | `idor,default_credentials` | [`xben-043-login-user-id-trust.sh`](xben-043-login-user-id-trust.sh) |
| 044 | Twig shop | `ssti` | [`xben-044-twig-ssti.sh`](xben-044-twig-ssti.sh) |
| 045 | Is There Anybody Out There? (with a twist) | `command_injection` | [`xben-045-command-injection-through-the-summary.sh`](xben-045-command-injection-through-the-summary.sh) |
| 046 | Cross 14 | `xss` | [`xben-046-xss-unlisted-tag-name.sh`](xben-046-xss-unlisted-tag-name.sh) |
| 047 | Cross 0 | `xss` | [`xben-047-xss-javascript-iframe-src.sh`](xben-047-xss-javascript-iframe-src.sh) |
| 048 | Cross 20 | `xss` | [`xben-048-xss-entities-for-parentheses.sh`](xben-048-xss-entities-for-parentheses.sh) |
| 049 | Cross 15 | `xss` | [`xben-049-xss-attribute-breakout.sh`](xben-049-xss-attribute-breakout.sh) |
| 050 | Cross 22 | `xss` | [`xben-050-xss-body-attribute-merge.sh`](xben-050-xss-body-attribute-merge.sh) |
| 051 | Cross 12 | `xss` | [`xben-051-xss-onfocus-again.sh`](xben-051-xss-onfocus-again.sh) |
| 052 | Auth 01 | `privilege_escalation,business_logic` | [`xben-052-hidden-field-privesc.sh`](xben-052-hidden-field-privesc.sh) |
| 053 | Jinja RCE | `ssti` | [`xben-053-jinja-rce.sh`](xben-053-jinja-rce.sh) |
| 054 | Auth 007 | `privilege_escalation,business_logic,http_method_tamper` | [`xben-054-http-method-tamper.sh`](xben-054-http-method-tamper.sh) |
| 055 | Auth 5 | `privilege_escalation,business_logic` | [`xben-055-strcmp-array-bypass.sh`](xben-055-strcmp-array-bypass.sh) |
| 056 | Art Gallery - Secrets | `ssti,default_credentials` | [`xben-056-django-template-injection.sh`](xben-056-django-template-injection.sh) |
| 057 | URL Bookmarks | `insecure_deserialization` | [`xben-057-pickle-cookie.sh`](xben-057-pickle-cookie.sh) |
| 058 | Easy IDOR GET | `idor` | [`xben-058-idor-get.sh`](xben-058-idor-get.sh) |
| 059 | Cross 6 | `xss` | [`xben-059-xss-javascript-string-breakout.sh`](xben-059-xss-javascript-string-breakout.sh) |
| 060 | Auth 6 | `privilege_escalation,crypto,default_credentials,brute_force` | [`xben-060-md5-magic-hash.sh`](xben-060-md5-magic-hash.sh) |
| 061 | Poision inclusion | `lfi` | [`xben-061-log-poisoning.sh`](xben-061-log-poisoning.sh) |
| 062 | Cross 3 | `xss` | [`xben-062-xss-substring-filter.sh`](xben-062-xss-substring-filter.sh) |
| 063 | Loan Calculator - Encoding | `ssti,default_credentials` | [`xben-063-jinja-ssti-past-two-filters.sh`](xben-063-jinja-ssti-past-two-filters.sh) |
| 064 | Cross 9 | `xss` | [`xben-064-xss-post-attribute-breakout.sh`](xben-064-xss-post-attribute-breakout.sh) |
| 065 | Cross 7 | `xss` | [`xben-065-xss-paired-script-tags-only.sh`](xben-065-xss-paired-script-tags-only.sh) |
| 067 | Medium file Upload | `arbitrary_file_upload,command_injection` | [`xben-067-upload-past-a-magic-number.sh`](xben-067-upload-past-a-magic-number.sh) |
| 068 | Service Dashboard | `command_injection` | [`xben-068-argument-injection.sh`](xben-068-argument-injection.sh) |
| 069 | IDOR Eats | `idor,privilege_escalation` | [`xben-069-idor-password-reset.sh`](xben-069-idor-password-reset.sh) |
| 070 | Cross 8 | `xss` | [`xben-070-xss-unfiltered.sh`](xben-070-xss-unfiltered.sh) |
| 071 | SQL make mistakes | `sqli` | [`xben-071-error-based-sqli.sh`](xben-071-error-based-sqli.sh) |
| 072 | Auth 2 | `privilege_escalation,business_logic,information_disclosure` | [`xben-072-client-side-auth.sh`](xben-072-client-side-auth.sh) |
| 073 | Is There Anybody Out There? | `command_injection` | [`xben-073-command-injection.sh`](xben-073-command-injection.sh) |
| 074 | Cross 4 | `xss` | [`xben-074-xss-alert-blacklisted.sh`](xben-074-xss-alert-blacklisted.sh) |
| 075 | URL Bookmarks - YAML | `insecure_deserialization` | [`xben-075-yaml-cookie.sh`](xben-075-yaml-cookie.sh) |
| 076 | SSTI Jinja | `ssti` | [`xben-076-ssti-jinja.sh`](xben-076-ssti-jinja.sh) |
| 077 | Upload your XXE | `xxe,arbitrary_file_upload` | [`xben-077-xxe-svg-upload.sh`](xben-077-xxe-svg-upload.sh) |
| 078 | Open eyes exfiltration | `sqli` | [`xben-078-union-exfiltration.sh`](xben-078-union-exfiltration.sh) |
| 079 | Poison Inclusion - Protected | `lfi` | [`xben-079-log-poisoning.sh`](xben-079-log-poisoning.sh) |
| 080 | SWIFT Shipping & Transport Inc. | `ssti` | [`xben-080-ssti-submission.sh`](xben-080-ssti-submission.sh) |
| 081 | PHP Deserialization | `insecure_deserialization` | [`xben-081-forged-serialized-cookie.sh`](xben-081-forged-serialized-cookie.sh) |
| 082 | Unlogic nginx interaction | `command_injection` | [`xben-082-nginx-njs-eval-chain.sh`](xben-082-nginx-njs-eval-chain.sh) |
| 083 | The secret category | `sqli` | [`xben-083-secret-category.sh`](xben-083-secret-category.sh) |
| 084 | S3aweed | `privilege_escalation,jwt,information_disclosure` | [`xben-084-open-bucket-to-master-account.sh`](xben-084-open-bucket-to-master-account.sh) |
| 085 | Auth 3 | `privilege_escalation,business_logic` | [`xben-085-x-forwarded-for-trust.sh`](xben-085-x-forwarded-for-trust.sh) |
| 086 | Repeat Me Please | `ssti` | [`xben-086-erb-injection.sh`](xben-086-erb-injection.sh) |
| 087 | Cross 30 | `xss` | [`xben-087-xss-no-uppercase-no-brackets.sh`](xben-087-xss-no-uppercase-no-brackets.sh) |
| 089 | Be the Admin | `privilege_escalation,business_logic` | [`xben-089-role-from-the-form.sh`](xben-089-role-from-the-form.sh) |
| 090 | Blog Raider | `idor,privilege_escalation` | [`xben-090-draft-idor.sh`](xben-090-draft-idor.sh) |
| 091 | JWT Tamper | `jwt,privilege_escalation` | [`xben-091-jwt-alg-none.sh`](xben-091-jwt-alg-none.sh) |
| 093 | Pay me Back | `ssti` | [`xben-093-ssti-in-a-reminder.sh`](xben-093-ssti-in-a-reminder.sh) |
| 094 | Site Saver | `command_injection` | [`xben-094-command-injection-in-a-url-check.sh`](xben-094-command-injection-in-a-url-check.sh) |
| 095 | Pab Users | `blind_sqli` | [`xben-095-blind-sqli-then-login.sh`](xben-095-blind-sqli-then-login.sh) |
| 096 | Library Services | `xxe` | [`xben-096-xxe-file-read.sh`](xben-096-xxe-file-read.sh) |
| 097 | XB APP 2 | `path_traversal` | [`xben-097-nginx-alias-traversal.sh`](xben-097-nginx-alias-traversal.sh) |
| 098 | XB APP 1 | `lfi,information_disclosure,path_traversal` | [`xben-098-private-file-read.sh`](xben-098-private-file-read.sh) |
| 099 | Get the first | `idor` | [`xben-099-objectid-reconstruction.sh`](xben-099-objectid-reconstruction.sh) |
| 100 | View the admins | `nosqli,graphql` | [`xben-100-graphql-nosql-filter.sh`](xben-100-graphql-nosql-filter.sh) |
| 101 | Bad Capcha | `crypto` | [`xben-101-padding-oracle-captcha.sh`](xben-101-padding-oracle-captcha.sh) |
| 102 | Email updates | `default_credentials,business_logic` | [`xben-102-update-someone-elses-email.sh`](xben-102-update-someone-elses-email.sh) |
| 103 | Trusty Cookie | `information_disclosure,idor,crypto,privilege_escalation` | [`xben-103-cbc-bitflip-cookie.sh`](xben-103-cbc-bitflip-cookie.sh) |
| 104 | Loan Calculator - Simple | `ssti,default_credentials` | [`xben-104-jinja-ssti-in-a-json-template.sh`](xben-104-jinja-ssti-in-a-json-template.sh) |


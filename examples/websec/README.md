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

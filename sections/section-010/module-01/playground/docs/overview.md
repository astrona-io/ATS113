# Overview: Work With OpenBao Tokens (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with OpenBao initialized and unsealed, adds some example secrets and policies, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, pod `openbao-0`, initialized and unsealed. The `bao` command-line tool is on your PATH.
- The Secret `openbao-init` in the namespace `openbao` with the lab-only unseal key and root token. A real installation never keeps these in Kubernetes.
- A KV version 2 secrets engine at `secret/` with `secret/inventory/db`, `secret/reports/q3`, `secret/ci/registry` and `secret/ops/runbook`.
- The policies `inventory-read` (reads `secret/data/inventory/*`), `reporting` (reads `secret/data/reports/*`) and a few more for later modules.
- A `tester` pod in the namespace `clients` with `curl` and `jq`.

Start the port-forward in a second terminal, then set the address and the lab-only root token:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Helpers

Paste these once in each new terminal. `token_summary` prints the most useful fields of one token. `try_read` reads one KV path with a given token and prints only whether it worked.

```sh
token_summary() {
  bao token lookup -format=json "$1" | jq '{policies: .data.policies, ttl: .data.ttl, period: .data.period, orphan: .data.orphan, type: .data.type, role: .data.role}'
}
try_read() {
  BAO_TOKEN="$1" bao kv get "$2" >/dev/null 2>&1 && echo "allowed" || echo "refused"
}
```

Use them like this: `token_summary $SOME_TOKEN`, `try_read $SOME_TOKEN secret/inventory/db`.

## Practice tasks

- Create a token with `-ttl=5m -explicit-max-ttl=8m`, renew it twice with `-increment=5m`, and predict the TTL after each renewal before you look.
- Create a periodic token with `-period=2m`, wait three minutes without renewing it, and look it up again.
- Build a three-level token tree and revoke the middle token. Which tokens are left?
- Create a token role that allows only `reporting`, then try to create a token through it with `-policy=inventory-read`.
- Create a batch token and try to renew it and to look it up by accessor. Note what OpenBao says each time.

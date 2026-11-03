# Overview: Response Wrapping And The Cubbyhole (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with OpenBao initialized and unsealed, adds some example secrets and policies, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, pod `openbao-0`, initialized and unsealed. The `bao` command-line tool is on your PATH.
- The Secret `openbao-init` in the namespace `openbao` with the lab-only unseal key and root token. A real installation never keeps these in Kubernetes.
- A KV version 2 secrets engine at `secret/` with `secret/inventory/db`, `secret/reports/q3`, `secret/ci/registry` and `secret/ops/runbook`.
- The policies `inventory-read`, `reporting`, `ci-deploy` and a few more.
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

Paste this once in each new terminal. `wrap_secret` wraps a KV read for five minutes and prints only the wrapping token.

```sh
wrap_secret() {
  bao kv get -wrap-ttl=5m -field=wrapping_token "$1"
}
```

Use it like this: `WRAPPED=$(wrap_secret secret/inventory/db)`.

## Practice tasks

- Write a note to the cubbyhole of two different tokens at the same path and read each back.
- Wrap a read, look the token up three times, then unwrap it and look it up again.
- Rewrap a wrapping token and try to unwrap the old one.
- Create a token with `bao token create -wrap-ttl=2m`, wait three minutes and try to unwrap it.
- Wrap your own data with `sys/wrapping/wrap` and check the creation path in a lookup.

# Overview: Manage Authentication Methods (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with OpenBao initialized and unsealed, adds some example secrets and policies, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, pod `openbao-0`, initialized and unsealed. The `bao` command-line tool is on your PATH.
- The Secret `openbao-init` in the namespace `openbao` with the lab-only unseal key and root token. A real installation never keeps these in Kubernetes.
- A KV version 2 secrets engine at `secret/` with `secret/inventory/db`, `secret/reports/q3`, `secret/ci/registry` and `secret/ops/runbook`.
- The policies `inventory-read`, `reporting`, `ci-deploy` and a few more.
- A `tester` pod in the namespace `clients` with `curl` and `jq`.
- No auth method except `token`.

Start the port-forward in a second terminal, then set the address and the lab-only root token:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Helpers

Paste this once in each new terminal. `mount_summary` prints the type, accessor and lease limits of one mount.

```sh
mount_summary() {
  bao read -format=json "sys/auth/$1" | jq '.data | {type, accessor, description, config}'
}
```

Use it like this: `mount_summary staff`.

## Practice tasks

- Enable `userpass` at `userpass/` and at `staff/`. Create a user in one and try to log in at the other.
- Tune `staff` with `-max-lease-ttl=1h`, create a user with `token_ttl=3h` and read the lease of a login.
- Set `-listing-visibility=unauth` and read `sys/internal/ui/mounts` with `curl` and no token.
- Disable a mount that has a live token and look the token up again.
- Write a policy that lets a token manage users at `auth/staff/users/*` and test that it cannot disable the mount.

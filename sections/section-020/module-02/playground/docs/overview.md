# Overview: Run AppRole In Production (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with OpenBao initialized and unsealed, the AppRole auth method enabled, and example secrets and policies, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, pod `openbao-0`, initialized and unsealed. The `bao` command-line tool is on your PATH.
- The Secret `openbao-init` in the namespace `openbao` with the lab-only unseal key and root token. A real installation never keeps these in Kubernetes.
- The AppRole auth method at `approle/`, with no roles.
- A KV version 2 secrets engine at `secret/` with `secret/inventory/db`, `secret/ci/registry` and `secret/ops/runbook`.
- The policies `ci-deploy`, `inventory-read` and a few more.
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

Paste this once in each new terminal. `approle_login` creates a `secret_id` for a role, logs in with it and prints only the policies of the resulting token.

```sh
approle_login() {
  local role_id secret_id
  role_id=$(bao read -field=role_id "auth/approle/role/$1/role-id")
  secret_id=$(bao write -f -field=secret_id "auth/approle/role/$1/secret-id")
  bao write -format=json auth/approle/login role_id="$role_id" secret_id="$secret_id" | jq '.auth.policies'
}
```

Use it like this: `approle_login deploy`.

## Practice tasks

- Create a role with `secret_id_num_uses=1` and try to log in twice with one `secret_id`.
- Create three `secret_id` values with different metadata, list their accessors and look one up.
- Destroy a `secret_id` by accessor and try to log in with it.
- Create a `secret_id` with `cidr_list=10.0.0.0/8` and log in from the tester pod.
- Create a limited orchestrator token and check that it cannot read the role or any secret.

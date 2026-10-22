# Overview: Log Machines In Without Long-Lived Secrets (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with OpenBao initialized and unsealed, a TLS listener, the inventory application and a client certificate, and then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- **OpenBao v2.7.1** in the namespace `openbao`, initialized and unsealed, with the lab-only root token in the Secret `openbao-init`. It answers with plain HTTP at `http://openbao.localtest.me:8200` and with TLS at `https://openbao-0.openbao-internal.openbao.svc.cluster.local:8443` (inside the cluster only).
- The policies `inventory-app`, `ci-deploy` and `reporting`, and a KV engine at `secret/` with example secrets.
- The namespace `inventory` with the ServiceAccount `inventory` and the pod `inventory-app` (with `curl`).
- The `tester` pod in the namespace `clients`, with `curl`, `jq` and a client certificate (`CN=reporting-job`) at `/certs`.
- The Secret `client-tls` in `clients`: the client certificate, its key and the lab CA. No auth method except tokens is enabled yet.

Start the port-forward in a second terminal, then set the address and the lab-only root token:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Helpers

Paste these once in each new terminal. `login_from_inventory_app` logs the `inventory-app` pod in with Kubernetes auth and the role you name. `login_with_certificate` logs the tester pod in with its client certificate and the certificate role you name.

```sh
login_from_inventory_app() {
  kubectl -n inventory exec deploy/inventory-app -- sh -c \
    "curl -s -X POST -d \"{\\\"role\\\":\\\"$1\\\",\\\"jwt\\\":\\\"\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)\\\"}\" http://openbao.localtest.me:8200/v1/auth/kubernetes/login"
}
login_with_certificate() {
  kubectl -n clients exec deploy/tester -- curl -s \
    --cacert /certs/ca.crt --cert /certs/tls.crt --key /certs/tls.key \
    -X POST -d "{\"name\":\"$1\"}" \
    https://openbao-0.openbao-internal.openbao.svc.cluster.local:8443/v1/auth/cert/login
}
```

Use them like this: `login_from_inventory_app inventory | jq .auth.policies`, `login_with_certificate reporting | jq .auth.policies`.

## Practice tasks

- Create an AppRole `secret_id` with `num_uses=2` and log in three times with it. Note which login fails and what the error says.
- Bind a Kubernetes auth role to the namespace `inventory` but the ServiceAccount `default`, log in from `inventory-app`, and read the error.
- Create a token for `inventory/default` with `kubectl create token` and try it against your role.
- Change the certificate role's `allowed_common_names` to `other-job` and log in again. Then set it back.
- Read `bao read auth/kubernetes/config` and find which values OpenBao filled in for itself.

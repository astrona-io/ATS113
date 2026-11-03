# Overview: Entity Operations And Identity Tokens (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with OpenBao initialized and unsealed, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, pod `openbao-0`, initialized and unsealed. The `bao` command-line tool is on your PATH.
- The Secret `openbao-init` in the namespace `openbao` with the lab-only unseal key and root token. A real installation never keeps these in Kubernetes.
- The userpass method with the user `alice` (password `alice-password`) and the policy `identity-reader`, which allows reading `identity/oidc/token/*`.
- An entity `alice` with an alias for the userpass login, and no metadata.
- A KV version 2 engine at `secret/` and a `tester` pod in the namespace `clients` with `curl` and `jq`.

Start the port-forward in a second terminal, then set the address and the lab-only root token:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Helpers

Paste these once in each new terminal. `alice_token` logs Alice in and prints the client token. `id_claims` reads an identity token for a role as Alice and prints its decoded payload.

```sh
alice_token() { bao write -field=token auth/userpass/login/alice password=alice-password; }
id_claims() {
  bao_jwt=$(BAO_TOKEN=$(alice_token) bao read -field=token "identity/oidc/token/$1")
  printf '%s' "$bao_jwt" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
}
```

Use them like this: `id_claims inventory-reader`.

## Practice tasks

- Add metadata to the entity, then change the template and watch the claims change.
- Create a second key with `ES256` and a role on it, and compare the JWT headers.
- Rotate the key and read the key set before and after.
- Disable the entity and try the login again. Then enable it.
- Merge a second entity into `alice` and read the result.
- Set a very short `verification_ttl`, rotate, and see when the old key leaves the key set.

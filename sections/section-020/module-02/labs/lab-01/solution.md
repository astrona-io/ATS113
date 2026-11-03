# Solution: Provision A Wrapped Secret ID

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the role settings, what the orchestrator policy allows, and the stored wrapping token.

## Step 1: Connect to OpenBao

Start the port-forward in a second terminal, then set the address and the lab-only root token:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao list auth/approle/role
```

The AppRole method is enabled and has no roles yet.

## Step 2: Create the role

```sh
bao write auth/approle/role/deploy token_policies=ci-deploy token_ttl=10m token_max_ttl=20m \
  secret_id_ttl=15m secret_id_num_uses=1
bao read auth/approle/role/deploy
```

The read shows `token_ttl` as 10 minutes, `secret_id_num_uses` as `1` and `bind_secret_id` as `true`.

## Step 3: Write the orchestrator policy

Save this as `deploy-orchestrator.hcl`:

```hcl
path "auth/approle/role/deploy/role-id" {
  capabilities = ["read"]
}

path "auth/approle/role/deploy/secret-id" {
  capabilities = ["update"]
}
```

```sh
bao policy write deploy-orchestrator deploy-orchestrator.hcl
```

## Step 4: Create the wrapped secret ID with the orchestrator token

```sh
ORCHESTRATOR_TOKEN=$(bao token create -policy=deploy-orchestrator -ttl=1h -field=token)
WRAPPED=$(BAO_TOKEN=$ORCHESTRATOR_TOKEN bao write -wrap-ttl=2h -f -field=wrapping_token auth/approle/role/deploy/secret-id)
bao write sys/wrapping/lookup token=$WRAPPED
kubectl -n clients create secret generic deploy-wrapped-secret-id --from-literal=token=$WRAPPED
```

The lookup shows the creation path `auth/approle/role/deploy/secret-id` and a TTL of `2h`. It does not use the token up.

## Step 5: Check the limits

```sh
BAO_TOKEN=$ORCHESTRATOR_TOKEN bao read auth/approle/role/deploy
BAO_TOKEN=$ORCHESTRATOR_TOKEN bao kv get secret/ci/registry
```

Both commands fail with `permission denied`.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create the wrapped `secret_id` with the root token | It works, but the grader checks the policy, and a stolen orchestrator token would have no limits |
| Give the policy `create` on `auth/approle/role/*` | The grader finds that the policy can read or change the role |
| Unwrap the token to test it | The token is used up |
| `secret_id_num_uses=0` | A `secret_id` can be used any number of times |

## Common mistakes

- Using `capabilities = ["create"]` on the `secret-id` path. The endpoint is an update.
- Storing the whole command output in the Secret instead of only the wrapping token.

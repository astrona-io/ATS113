# What A Token Carries

When OpenBao refuses a request, the first question is always the same: which token sent it, and what does that token allow? This part looks inside one token. It shows the fields OpenBao keeps for every token, where they come from, and the command that shows them.

## Every request carries a token

A **token** is a random string that a client sends with every request to OpenBao. OpenBao looks the token up in its token store, finds the policies attached to it, and decides whether the request is allowed. A **policy** is a set of rules that names paths and the capabilities allowed on them, such as `read` or `update`. With the `bao` command-line tool the token travels in the environment variable `BAO_TOKEN`; over the HTTP API it travels in the request header `X-Vault-Token`. OpenBao kept that header name from Vault, the project it was forked from.

Tokens come from the **token auth method**, the one auth method that is always enabled, at the path `auth/token/`. Every other auth method, such as AppRole or Kubernetes, checks its own kind of proof and then asks the token auth method to create a token. So everything in this part applies to every login.

Start with the token you already have. The environment keeps a lab-only root token in a Kubernetes Secret; a real installation revokes its root token once setup is done.

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao token lookup
```

`bao token lookup` with no argument looks up the token in `BAO_TOKEN`. The root token shows the policy `root`, a TTL of zero, which means it never expires, and no parent. The `root` policy allows everything, which is exactly why no service should ever hold it.

## Create a token with one policy

Now create the kind of token a service would get: one policy, a time limit, and nothing else.

```sh
bao token create -policy=inventory-read -ttl=1h -display-name=inventory-test
```

OpenBao answers with a table. The fields that matter most are these:

| Field | What it is |
| --- | --- |
| `token` | The secret string the service sends with every request |
| `token_accessor` | A second ID for the same token; it can look the token up, renew it or revoke it, but not use it |
| `token_duration` | The time to live (TTL): how long the token is valid from now |
| `token_renewable` | Whether the TTL can be extended by renewing |
| `token_policies` | The policies attached: `default` and `inventory-read` |

The `default` policy is attached to every token unless you ask OpenBao not to. It lets a token look itself up, renew itself and revoke itself, and little else. Save the new token in a shell variable so you can use it:

```sh
INVENTORY_TOKEN=$(bao token create -policy=inventory-read -ttl=1h -field=token)
BAO_TOKEN=$INVENTORY_TOKEN bao kv get secret/inventory/db
BAO_TOKEN=$INVENTORY_TOKEN bao kv get secret/reports/q3
```

The first read succeeds. The second fails with `permission denied`, because `inventory-read` names only `secret/data/inventory/*`. The token carries exactly what its policies allow, and nothing more.

## The accessor: manage a token without holding it

An administrator often needs to see or revoke a token they must never be able to use. The **accessor** solves this. It identifies the token but cannot be used to make requests, so it is safe to log and to pass around.

```sh
INVENTORY_ACCESSOR=$(bao token lookup -format=json $INVENTORY_TOKEN | jq -r '.data.accessor')
bao token lookup -accessor $INVENTORY_ACCESSOR
```

The lookup through the accessor shows the same policies, TTL and display name, but not the token itself. OpenBao also writes accessors, not tokens, into its audit log, so an operator can follow a token through the log without seeing the secret. To check what a token may do on one path without trying it, ask OpenBao directly:

```sh
bao token capabilities $INVENTORY_TOKEN secret/data/inventory/db
```

OpenBao answers with the capabilities the token has on that path, here `read`.

You now know what a token carries: policies, a TTL, a renewable flag and an accessor, plus the `default` policy unless you remove it. You can read all of it with `bao token lookup`, by token or by accessor. The open question is what happens when the TTL runs out, and how a service keeps its token alive.

## Common pitfalls

> [!WARNING]
> - **Giving a service the root token.** It never expires and allows everything. A leaked root token means a leaked OpenBao.
> - **Logging tokens instead of accessors.** A token in a log file is a working credential. Log the accessor.
> - **Forgetting the `default` policy.** Every token gets it unless you create it with `-no-default-policy`. Read `token_policies`, not only the policies you asked for.
> - **Reading the wrong path in a policy.** KV version 2 stores data under `secret/data/...`, so a policy on `secret/inventory/*` matches nothing that `bao kv get secret/inventory/db` reads.

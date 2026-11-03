# Solution: Deliver A Secret With A Wrapping Token

Work the task yourself first. Running `astrona submit -c sections/section-010/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the stored wrapping token, the service token with its note, and that the note stays private to that token.

## Step 1: Connect to OpenBao

Start the port-forward in a second terminal, then set the address and the lab-only root token:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao kv get secret/inventory/db
```

The read works with the root token and shows the secret you will wrap.

## Step 2: Wrap the secret and store the token

The `-field=wrapping_token` flag prints only the token:

```sh
WRAPPED=$(bao kv get -wrap-ttl=1h -field=wrapping_token secret/inventory/db)
bao write sys/wrapping/lookup token=$WRAPPED
kubectl -n clients create secret generic inventory-wrapped --from-literal=token=$WRAPPED
```

The lookup does not use the token up. It shows the creation path `secret/data/inventory/db` and a creation TTL of `1h`.

## Step 3: Create the service token and write the note with it

The note must be written with the service token itself, because a cubbyhole belongs to one token:

```sh
SERVICE_TOKEN=$(bao token create -policy=inventory-read -display-name=inventory-service -field=token)
BAO_TOKEN=$SERVICE_TOKEN bao write cubbyhole/deploy-note text=ready
BAO_TOKEN=$SERVICE_TOKEN bao read cubbyhole/deploy-note
kubectl -n clients create secret generic inventory-service-token --from-literal=token=$SERVICE_TOKEN
```

The read shows the key `text` with the value `ready`.

## Step 4: Prove the note is private

The root token has its own cubbyhole and finds nothing at that path:

```sh
bao read cubbyhole/deploy-note
BAO_TOKEN=$SERVICE_TOKEN bao kv get secret/reports/q3
```

The first command reports that no value was found. The second fails with `permission denied`.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Write the note with the root token | The note is in the cubbyhole of the root token, and the service token finds nothing |
| Unwrap the token to check it | The token is used up and the grader finds no valid wrapping token |
| Wrap with `-wrap-ttl=5m` | The grader needs a creation TTL of exactly 1 hour |

## Common mistakes

- Forgetting `-field=wrapping_token` and storing the whole table output in the Secret.
- Creating the service token and leaving `BAO_TOKEN` set to the root token when writing the note.

# Solution: Issue A Periodic Token For A Service

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the stored token's settings, that it renews back to 24 hours, and that it reads only inventory secrets.

## Step 1: Connect to OpenBao

Start the port-forward in a second terminal, then set the address and the lab-only root token:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao policy read inventory-read
```

The policy allows `read` on `secret/data/inventory/*`, which is what the service needs.

## Step 2: Create the token

One command sets every property the task asks for. `-orphan` gives the token no parent, `-period=24h` makes it periodic, and the type defaults to `service`. Creating orphan and periodic tokens needs the root token or `sudo`, which you have in this lab.

```sh
INVENTORY_TOKEN=$(bao token create -orphan -period=24h -policy=inventory-read \
  -display-name=inventory-service -field=token)
bao token lookup $INVENTORY_TOKEN
```

The lookup shows `orphan` as `true`, `period` as `24h`, `type` as `service`, and the policies `default` and `inventory-read`.

## Step 3: Store it for the service

```sh
kubectl -n clients create secret generic inventory-service-token --from-literal=token=$INVENTORY_TOKEN
```

## Step 4: Prove it

Renew the token with its own credential, as the service would, and try one allowed and one refused read:

```sh
BAO_TOKEN=$INVENTORY_TOKEN bao token renew
BAO_TOKEN=$INVENTORY_TOKEN bao kv get secret/inventory/db
BAO_TOKEN=$INVENTORY_TOKEN bao kv get secret/reports/q3
```

The renewal resets the TTL to 24 hours, the inventory read succeeds and the reports read fails with `permission denied`.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Store the root token | The grader rejects any token with `root`; a leak would expose everything |
| `-ttl=8760h` instead of a period | The token cannot outlive the mount's max TTL (32 days by default) and never renews back |
| `-type=batch` | Batch tokens cannot be renewed or be periodic |
| Leave out `-orphan` | The token is a child of the root token; revoking the root token after setup would revoke it too |

## Common mistakes

- Creating the token with your own token in `BAO_TOKEN` after you changed it to the inventory token. Check `bao token lookup` before you create.
- Storing the token under a key other than `token`.

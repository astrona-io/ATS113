# Solution: Set Up A Tuned Staff Login

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the mount and its lease limits, a real login of Alice with the right lease, and what her token can read.

## Step 1: Connect to OpenBao

Start the port-forward in a second terminal, then set the address and the lab-only root token:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao auth list
```

Only the `token/` method is listed.

## Step 2: Mount and tune

The `-path` flag puts the mount at `staff`, and `bao auth tune` sets the two limits on `auth/staff`:

```sh
bao auth enable -path=staff -description="Logins for staff" userpass
bao auth tune -default-lease-ttl=2h -max-lease-ttl=8h auth/staff
bao read -format=json sys/auth/staff | jq '.data.config'
```

The config shows `7200` and `28800` seconds.

## Step 3: Create the user

```sh
bao write auth/staff/users/alice password=alice-password \
  token_policies=inventory-read token_ttl=30m token_max_ttl=1h
```

## Step 4: Prove it

Log in as Alice and read with her token:

```sh
ALICE_TOKEN=$(bao write -field=token auth/staff/login/alice password=alice-password)
BAO_TOKEN=$ALICE_TOKEN bao token lookup
BAO_TOKEN=$ALICE_TOKEN bao kv get secret/inventory/db
BAO_TOKEN=$ALICE_TOKEN bao kv get secret/reports/q3
```

The lookup shows a TTL of about 30 minutes and the policies `default` and `inventory-read`. The inventory read works and the reports read fails with `permission denied`.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `bao auth enable userpass` without `-path` | The mount is at `userpass/`, so `auth/staff/login/alice` does not exist |
| Leave out `token_ttl` | The token gets the 2 hour default of the mount, not 30 minutes |
| `-policy=root` or a wider policy for convenience | The grader checks the exact policy list |

## Common mistakes

- Running `bao auth tune` with `staff` instead of `auth/staff`.
- Writing the user with `policies=` and then reading `token_policies` back as empty on a newer method version. Use `token_policies`.

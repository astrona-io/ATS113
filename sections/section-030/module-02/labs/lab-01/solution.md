# Solution: Log In From The Directory

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the method's configuration, the policies of three real logins, and what each token can read.

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

## Step 2: Look at the directory

Search from inside the directory pod with the read-only account, to learn the right values:

```sh
kubectl -n ldap exec deploy/openldap -- ldapsearch -x -H ldap://localhost:389 \
  -D cn=readonly,dc=example,dc=org -w readonly-password \
  -b dc=example,dc=org '(|(uid=alice)(cn=engineers))' dn
```

The result lists `uid=alice,ou=people,dc=example,dc=org` and `cn=engineers,ou=groups,dc=example,dc=org`. This confirms `uid` for users and `cn` for groups.

## Step 3: Enable and configure

```sh
bao auth enable ldap
bao write auth/ldap/config \
  url=ldap://openldap.ldap.svc.cluster.local:389 \
  binddn=cn=readonly,dc=example,dc=org bindpass=readonly-password \
  userdn=ou=people,dc=example,dc=org userattr=uid \
  groupdn=ou=groups,dc=example,dc=org groupattr=cn
```

## Step 4: Map the groups

```sh
bao write auth/ldap/groups/engineers policies=inventory-read
bao write auth/ldap/groups/auditors policies=reporting
```

## Step 5: Prove it

```sh
bao write auth/ldap/login/alice password=alice-password
bao write auth/ldap/login/carol password=carol-password
ALICE_TOKEN=$(bao write -field=token auth/ldap/login/alice password=alice-password)
BAO_TOKEN=$ALICE_TOKEN bao kv get secret/inventory/db
BAO_TOKEN=$ALICE_TOKEN bao kv get secret/reports/q3
```

Alice's login lists `default` and `inventory-read`. Carol's lists only `default`. The inventory read works and the reports read fails with `permission denied`.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Leave `userattr` at the default `cn` | The search finds no user named `alice`; the login fails |
| Use the directory administrator as `binddn` | The grader rejects it; a leaked `bindpass` would allow changes in the directory |
| Create `auth/ldap/users/` mappings for each person | Works for these three, but the grader checks that groups drive access |
| Map `root` or a broad policy to a group | Members get more than the task allows |

## Common mistakes

- Naming the group mapping after the DN instead of `engineers`.
- Forgetting `groupattr=cn`, which leaves the groups unnamed in the way the mapping expects.

# Configure LDAP Auth Against OpenLDAP

With the login steps in mind, the configuration is a short list of values. This part enables the method, writes the values for the playground's OpenLDAP and tests a login. You will also meet the first thing that goes wrong, a user with no policies.

## Look at the directory first

A wrong value is much easier to find when you know what the directory holds. The playground's `tester` pod has no LDAP tools, but the OpenLDAP pod does. Search for Alice from inside it:

<!-- astrona:playground:renew -->

```sh
kubectl -n ldap exec deploy/openldap -- ldapsearch -x -H ldap://localhost:389 \
  -D cn=readonly,dc=example,dc=org -w readonly-password \
  -b ou=people,dc=example,dc=org '(uid=alice)' dn
```

The result contains one entry with the DN `uid=alice,ou=people,dc=example,dc=org`. The base `-b` is the `userdn` for OpenBao, and `uid` is the `userattr`. Now look for the groups that have Alice as a member:

```sh
kubectl -n ldap exec deploy/openldap -- ldapsearch -x -H ldap://localhost:389 \
  -D cn=readonly,dc=example,dc=org -w readonly-password \
  -b ou=groups,dc=example,dc=org '(member=uid=alice,ou=people,dc=example,dc=org)' cn
```

The result is the group `engineers`. The base is the `groupdn`, and the attribute `cn` is the `groupattr`. These two searches are exactly what OpenBao does in steps 3 and 5.

## Enable and configure the method

Set the connection values and enable the method:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao auth enable ldap
bao write auth/ldap/config \
  url=ldap://openldap.ldap.svc.cluster.local:389 \
  binddn=cn=readonly,dc=example,dc=org \
  bindpass=readonly-password \
  userdn=ou=people,dc=example,dc=org \
  userattr=uid \
  groupdn=ou=groups,dc=example,dc=org \
  groupattr=cn
bao read auth/ldap/config
```

The read shows the values. It shows `binddn` and leaves out `bindpass`, because OpenBao never returns the bind password. The `url` here uses plain `ldap://`, which sends the password unencrypted. That is acceptable for a lab network only; the last part of this module turns encryption on.

## Log in

Alice has no mapping yet, so her token will have only the `default` policy. Log in to see what the login returns:

```sh
bao write auth/ldap/login/alice password=alice-password
```

The response has an `auth` block with `policies` set to `default`, a `token_policies` list with the same value, and metadata with `username` set to `alice`. The password was right, but nothing says what Alice may do. Try to read a secret with this token:

```sh
ALICE_TOKEN=$(bao write -field=token auth/ldap/login/alice password=alice-password)
BAO_TOKEN=$ALICE_TOKEN bao kv get secret/inventory/db
```

The read fails with `permission denied`. The login is working and the policy mapping is missing. Next you add it.

## Log in from the command line as a person would

A person uses `bao login`, which asks for the password without echoing it:

```sh
bao login -method=ldap username=alice
```

The command prompts for the password, stores the token in the token helper file and prints its policies. The `-path` option selects a mount that is not at `ldap/`.

You now have a working LDAP login with no authorization. The next part connects the groups to policies.

## Common pitfalls

> [!WARNING]
> - **Putting `bindpass` in a shell history or a script.** Pass it from a file or an environment variable, and rotate it if it leaked.
> - **Using `ldap://` outside a lab.** The user's password travels in clear text between OpenBao and the directory.
> - **Testing the login with the root token set.** `bao login` replaces the stored token, but `BAO_TOKEN` in the environment still overrides it. Unset it first.
> - **Reading `bindpass` back to check it.** The read never returns it. Test with a login instead.

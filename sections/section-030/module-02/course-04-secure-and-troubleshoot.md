# Secure And Troubleshoot LDAP Login

The lab setup works, but it sends passwords in clear text and trusts the directory's answers blindly. This part closes the main gaps, then lists the errors you will see and the check behind each.

## Encrypt the connection

OpenBao can encrypt the connection in two ways. **LDAPS** uses a URL such as `ldaps://directory.example.org:636` and encrypts from the first byte. **StartTLS** starts on the plain port 389 and upgrades the connection before any password is sent. Turn StartTLS on with the field `starttls`, and give OpenBao the certificate authority that signed the directory's certificate in the field `certificate`:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao read auth/ldap/config
```

The read lists `starttls`, `insecure_tls`, `certificate` and `tls_min_version`. The playground directory has no certificate, so the lab stays on plain `ldap://`. In a real setup, write the values with `bao write auth/ldap/config starttls=true certificate=@ca.pem` and leave `insecure_tls` at `false`. Setting `insecure_tls=true` turns off the certificate check and makes the encryption worthless against an attacker in the network.

## Refuse empty passwords

LDAP has a quirk: a bind with a user name and an **empty password** is an unauthenticated bind, and many directories report it as a success. A login that skips the password check would then let anyone in. OpenBao refuses empty-password binds by default through `deny_null_bind=true`. Do not turn it off:

```sh
bao read -field=deny_null_bind auth/ldap/config
bao write auth/ldap/login/alice password=""
```

The first command prints `true`. The second request is refused.

## Rotate the bind password

The `bindpass` belongs to a service account, so rotate it on the schedule you rotate any service password. Change it in the directory first and then in OpenBao. Until both match, every login fails at step 2. Write only the changed field:

```sh
bao write auth/ldap/config bindpass=new-readonly-password
```

In the playground this would break logins, because the directory still has the old password. It shows why the order matters.

## Errors and where to look

| What you see | Likely cause | What to check |
| --- | --- | --- |
| `ldap operation failed: failed to bind as user` | The user's password is wrong, or the user was not found | Search for the user with `ldapsearch` using the same `userdn` and `userattr` |
| An error that the search bind failed, with LDAP result code 49 (Invalid Credentials) | The `binddn` or `bindpass` is wrong | Try the bind in `ldapsearch` with the same values |
| A login works but the token has only `default` | No policy is mapped to the user's groups | Compare `bao list auth/ldap/groups` with the group names in the directory |
| A group is never found | `groupdn`, `groupattr` or `groupfilter` is wrong | Run the group search by hand |
| Connection errors or timeouts | The URL, the network or TLS | Check the URL and, for TLS, the CA certificate |

Check the directory directly with `ldapsearch` before you change anything in OpenBao. The two searches from the configuration part are the same requests OpenBao makes, and if they do not return what you expect, the OpenBao configuration cannot be the cause.

The server log helps too. Read the OpenBao log for the lines about LDAP while you repeat a failing login:

```sh
kubectl -n openbao logs openbao-0 --tail=30
```

You now have the whole path: how the login works, how to configure it, how to map policies and how to secure and debug it. The method is the simplest way to reuse a company directory, and the next step in a larger setup is to join the directory groups into the OpenBao identity system.

## Common pitfalls

> [!WARNING]
> - **Setting `insecure_tls=true` to make a certificate error go away.** Fix the CA instead.
> - **Disabling `deny_null_bind`.** Anyone could log in with an empty password if the directory allows unauthenticated binds.
> - **Changing `bindpass` in OpenBao before the directory.** All logins fail until both match.
> - **Debugging in OpenBao first.** Run the directory search by hand and find which of the two searches fails.

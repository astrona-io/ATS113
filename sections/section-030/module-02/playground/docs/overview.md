# Overview: Log People In From A Directory With LDAP (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with OpenBao initialized and unsealed, an OpenLDAP directory with three people and two groups, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, pod `openbao-0`, initialized and unsealed. The `bao` command-line tool is on your PATH.
- The Secret `openbao-init` in the namespace `openbao` with the lab-only unseal key and root token. A real installation never keeps these in Kubernetes.
- **OpenLDAP** in the namespace `ldap` for `dc=example,dc=org`, at `ldap://openldap.ldap.svc.cluster.local:389`. People are below `ou=people` and log in with `uid`: `alice`, `bob` and `carol` with the passwords `alice-password`, `bob-password` and `carol-password`.
- The groups `engineers` (Alice) and `auditors` (Bob) below `ou=groups`. Carol is in no group.
- The read-only search account `cn=readonly,dc=example,dc=org` with the password `readonly-password`, and the administrator `cn=admin,dc=example,dc=org` with `admin-password`.
- A KV version 2 engine at `secret/` and the policies `inventory-read` and `reporting`.
- A `tester` pod in the namespace `clients` with `curl` and `jq`. No auth method except `token` is enabled.

Start the port-forward in a second terminal, then set the address and the lab-only root token:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Helpers

Paste these once in each new terminal. `ldap_search` runs a search in the directory pod with the read-only account. `ldap_policies` logs a user in and prints the policies of the token.

```sh
ldap_search() {
  kubectl -n ldap exec deploy/openldap -- ldapsearch -x -H ldap://localhost:389 \
    -D cn=readonly,dc=example,dc=org -w readonly-password -b dc=example,dc=org "$@"
}
ldap_policies() {
  bao write -format=json "auth/ldap/login/$1" password="$1-password" | jq '.auth.policies'
}
```

Use them like this: `ldap_search '(uid=alice)' dn` and `ldap_policies alice`.

## Practice tasks

- Configure the method with the default `userattr` and read the error of a login. Then set `userattr=uid`.
- Map a group, change Alice's membership in the directory with `ldapmodify` as the administrator, and log in again.
- Add a user mapping for Carol and check the policies of her token.
- Turn `case_sensitive_names` on and map `Engineers` instead of `engineers`.
- Use a wrong `bindpass` and read the error. Then fix it.

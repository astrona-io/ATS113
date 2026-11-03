# Log People In From A Directory With LDAP

Most companies already keep their people in a directory: every employee has an account, and groups such as `engineers` say what they do. Asking each person to create a second password in OpenBao duplicates that data and leaves two places to update when someone leaves. The LDAP auth method lets OpenBao check the password against the directory and map the person's groups to policies.

**LDAP** (Lightweight Directory Access Protocol) is the standard protocol to read and check entries in a directory server such as OpenLDAP or Active Directory. An entry has a **distinguished name** (DN), a unique path such as `uid=alice,ou=people,dc=example,dc=org`, and attributes such as `uid` and `cn`. In this module OpenBao is the LDAP client, and the playground runs an OpenLDAP server.

The module has four parts. **How LDAP Login Works** follows one login from the password to the token and lists the settings that decide each step. **Configure LDAP Auth Against OpenLDAP** sets the method up and logs in. **Map Groups And Users To Policies** gives each group its policies; a graded lab follows it. **Secure And Troubleshoot LDAP Login** covers encryption, rejected empty passwords and the errors you will meet.

## Learning objectives

After this module you can:

- Describe the steps OpenBao takes to log a user in against an LDAP directory.
- Configure `auth/ldap/config` with a bind account, user search and group search.
- Map LDAP groups and individual users to policies.
- Predict the policies of a user who belongs to several groups, or to none.
- Turn on StartTLS or LDAPS and keep empty-password binds off.
- Find the cause of a refused login from the error and a direct directory query.

## Before you start

You should know what a token, a policy and a TTL are, and be able to run `bao` against OpenBao. You do not need to know LDAP; the module defines every term it uses.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1**, initialized and unsealed, and the `bao` command-line tool on your PATH. It holds:

| Object | What it is |
| --- | --- |
| OpenLDAP (namespace `ldap`, Service `openldap`) | A directory for `dc=example,dc=org`, reachable at `ldap://openldap.ldap.svc.cluster.local:389` |
| Users `alice`, `bob`, `carol` | Entries under `ou=people`, with the passwords `alice-password`, `bob-password` and `carol-password` |
| Groups `engineers`, `auditors` | Entries under `ou=groups`; `alice` is in `engineers`, `bob` is in `auditors`, `carol` is in none |
| Search account `cn=readonly,dc=example,dc=org` | Password `readonly-password`; it can read the directory |
| KV engine `secret/` | With `secret/inventory/db` and `secret/reports/q3` |
| Policies `inventory-read`, `reporting` | Read `secret/data/inventory/*` and `secret/data/reports/*` |
| Pod `tester` (namespace `clients`) | Has `curl` and `jq` |

Start the port-forward in a second terminal (`kubectl -n openbao port-forward svc/openbao 8200:8200`) and set `BAO_ADDR` and `BAO_TOKEN` as the parts show.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

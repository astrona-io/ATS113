# Manage Authentication Methods

A team enables the `userpass` auth method for its staff, and a month later a contractor needs logins with shorter sessions. Someone enables a second copy at another path, forgets which one is which, and later disables the wrong one. Every token that mount issued stops working at once. Knowing how auth methods are mounted, tuned and removed prevents this kind of outage.

An **auth method** is a plugin that checks some proof of identity and returns a token. OpenBao mounts each auth method at a path below `auth/`, and the same method can be mounted several times at different paths. Each mount has its own users or roles, its own settings and its own accessor, the ID that identifies the mount.

The module has four parts. **Enable, List And Disable Auth Methods** shows the mount commands and what disabling does to tokens. **Tune An Auth Method** changes the lease limits, token type and visibility of a mount. **Token Settings On Logins** covers the `token_*` fields that every auth method accepts on a user or role; a graded lab follows it. **Log In From The CLI And Delegate Administration** shows `bao login` and a policy that lets a team manage one mount.

## Learning objectives

After this module you can:

- Enable an auth method at the default path and at a custom path, and enable the same method twice.
- Read a mount's type, accessor and configuration with `bao auth list -detailed`.
- Explain what disabling an auth method does to the tokens it issued.
- Tune the default and maximum lease TTL, the token type and the listing visibility of a mount.
- Set `token_policies`, `token_ttl`, `token_max_ttl`, `token_period` and `token_bound_cidrs` on a login.
- Log in with `bao login` and write a policy that manages only one auth mount.

## Before you start

You should know what a token, a policy and a TTL are, and be able to run `bao` against OpenBao. No auth method knowledge is needed; the module uses `userpass`, the simplest one, as its example.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1**, initialized and unsealed, and the `bao` command-line tool on your PATH. It holds:

| Object | What it is |
| --- | --- |
| KV engine `secret/` | A key-value secrets engine (version 2) with `secret/inventory/db` and `secret/reports/q3` |
| Policies `inventory-read`, `reporting`, `ci-deploy` | Read `secret/data/inventory/*`, `secret/data/reports/*` and `secret/data/ci/*` |
| Secret `openbao-init` (namespace `openbao`) | The lab-only unseal key and root token |
| Pod `tester` (namespace `clients`) | Has `curl` and `jq` |

Start the port-forward in a second terminal (`kubectl -n openbao port-forward svc/openbao 8200:8200`) and set `BAO_ADDR` and `BAO_TOKEN` as the parts show.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

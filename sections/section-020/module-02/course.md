# Run AppRole In Production

An AppRole login with a `role_id` and a `secret_id` is easy to set up in a test. In production, three questions decide whether it is safe: who is allowed to create a `secret_id`, how it reaches the job, and what happens to the ones that are no longer needed. A team that answers these with "the administrator, over chat, never" ends up with long-lived secrets in many places, which is the problem AppRole was meant to remove.

**AppRole** is an auth method where a machine logs in with a public `role_id` and a secret `secret_id`. A **role** is the object that holds the rules: which policies the token gets, how long it lives and how the `secret_id` is limited. This module takes a working AppRole role and makes it fit for production.

The module has four parts. **Role Settings And The Role ID** covers every field of a role that matters for safety. **Pull And Push Secret IDs** shows the two ways a `secret_id` comes into existence. **Deliver A Secret ID Wrapped** gives a limited orchestrator the right to create `secret_id` values and wraps each one for delivery; a graded lab follows it. **Manage And Revoke Secret IDs** shows accessors, lookup, destruction and cleanup.

## Learning objectives

After this module you can:

- Create an AppRole role with short token lifetimes and a single-use `secret_id`.
- Read and set the `role_id` of a role.
- Explain pull and push modes and create a `secret_id` in each.
- Write a policy that lets an orchestrator create a `secret_id` for one role and nothing else.
- Deliver a `secret_id` as a wrapping token.
- List, look up and destroy `secret_id` values by accessor.

## Before you start

You should know what a token, a policy and a TTL are, how response wrapping works at a basic level (a wrapping token is a single-use token that holds one stored response), and how to run `bao` against OpenBao. The first AppRole login with `role_id` and `secret_id` should not be new to you.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1**, initialized and unsealed, and the `bao` command-line tool on your PATH. It holds:

| Object | What it is |
| --- | --- |
| Auth method `approle/` | Enabled, with no roles |
| KV engine `secret/` | A key-value secrets engine (version 2) with `secret/ci/registry` and `secret/inventory/db` |
| Policies `ci-deploy`, `inventory-read` | Read `secret/data/ci/*` and `secret/data/inventory/*` |
| Secret `openbao-init` (namespace `openbao`) | The lab-only unseal key and root token |
| Pod `tester` (namespace `clients`) | Has `curl` and `jq` |

Start the port-forward in a second terminal (`kubectl -n openbao port-forward svc/openbao 8200:8200`) and set `BAO_ADDR` and `BAO_TOKEN` as the parts show.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

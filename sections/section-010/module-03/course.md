# Response Wrapping And The Cubbyhole

An administrator needs to hand a database password to a deployment job. Pasting it into a chat message or a ticket leaves a copy in places nobody controls. OpenBao can instead hand over a single-use ticket that holds the password, valid for a few minutes. If anyone else uses the ticket first, the job sees that it is already spent and knows the secret leaked.

That ticket is a **wrapping token**: a token whose only content is a response that OpenBao stored in a private place. The private place is the **cubbyhole**, a small secret store that every token owns and that no other token can read. **Response wrapping** is the feature that puts any response into a new wrapping token's cubbyhole.

The module has four parts. **The Cubbyhole** shows the private storage that every token has. **Wrap And Unwrap A Response** creates and opens a wrapping token. **Lookup, Rewrap And Wrap Your Own Data** covers inspecting a wrapping token without opening it, extending it and wrapping data you supply; a graded lab follows it. **Safe Delivery With Wrapped Responses** puts the pieces into a delivery workflow and shows how to detect a stolen secret.

## Learning objectives

After this module you can:

- Write to and read from a token's cubbyhole, and explain why no other token can read it.
- Wrap the response of any read with a wrapping TTL and unwrap it once.
- Look up a wrapping token to check its creation path and TTL without opening it.
- Rewrap a wrapping token and wrap data you supply with `sys/wrapping/wrap`.
- Explain how a failed unwrap shows that a secret was intercepted.

## Before you start

You should know what a token, a policy and a TTL are, and be able to run `bao` against OpenBao. You need no auth method other than `token`.

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

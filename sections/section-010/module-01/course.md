# Work With OpenBao Tokens

A service that reads its database password from OpenBao at startup works fine for a day. Then, one morning, every request fails with `permission denied`. Nothing changed in the service or its policy: its token simply reached the end of its life. Knowing how long a token lives, and how to keep it alive, is the first skill every OpenBao operator needs.

A **token** is the credential every request to OpenBao carries. OpenBao reads the token, finds its policies, and allows or refuses the request. Every auth method, from a password login to a Kubernetes login, ends by creating a token, so everything in this module applies to every login you will configure later.

The module has three parts. **What A Token Carries** looks inside one token: its policies, its accessor and its time to live. **TTLs, Renewal And Periodic Tokens** shows how renewal works and how a periodic token lets a service run for months; a graded lab follows it. **Service And Batch Tokens, Orphans And Token Roles** covers the two token types, the token tree that revokes children with their parent, and token roles.

## Learning objectives

After this module you can:

- Read a token's policies, TTL, accessor, type and parent with `bao token lookup`.
- Explain the difference between a TTL, a max TTL and an explicit max TTL.
- Renew a token and predict the TTL it gets back.
- Create a periodic token for a service, and explain why it suits services and not people.
- Choose between service and batch tokens.
- Explain the token tree, and create an orphan token that survives its parent.
- Create a token role and issue tokens through it.

## Before you start

You need Kubernetes basics (`kubectl get`, `kubectl exec`, Secrets) and you should know that OpenBao must be unsealed before it answers. You do not need to know any auth method yet.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1**, already initialized and unsealed, and the `bao` command-line tool on your PATH. It holds:

| Object | What it is |
| --- | --- |
| KV engine `secret/` | A key-value secrets engine (version 2) with `secret/inventory/db` and `secret/reports/q3` |
| Policy `inventory-read` | Allows reading `secret/data/inventory/*` |
| Policy `reporting` | Allows reading `secret/data/reports/*` |
| Secret `openbao-init` (namespace `openbao`) | The lab-only unseal key and root token |

Every command in the parts runs against the playground. Start the port-forward in a second terminal (`kubectl -n openbao port-forward svc/openbao 8200:8200`) and set `BAO_ADDR` and `BAO_TOKEN` as the parts show.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

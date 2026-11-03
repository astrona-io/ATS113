# Prerequisites

Before starting this lab you should be able to:

- Use the `bao` command-line tool with `BAO_ADDR` and `BAO_TOKEN`.
- Log in with the userpass method.
- Read the three parts of a JWT with `jq`, or follow the example in the solution.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **OpenBao v2.7.1**, initialized and unsealed, and the `bao` command-line tool on your PATH. The lab-only root token is in the Secret `openbao-init` in the namespace `openbao`.
- A `tester` pod in the namespace `clients`, with `curl` and `jq`.
- The userpass user `alice` (password `alice-password`) with the policy `identity-reader`, and an entity `alice` with an alias for that login.

Nothing the task asks you to create has been created for you.

## Working rules

- Start the port-forward in a second terminal and set the address:
  `kubectl -n openbao port-forward svc/openbao 8200:8200`, then
  `export BAO_ADDR=http://openbao.localtest.me:8200`.
- Everything is graded on the **final state** of OpenBao, so leave your work in place.
- Read a token as Alice and decode it before you submit.

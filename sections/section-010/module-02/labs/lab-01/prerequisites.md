# Prerequisites

Before starting this lab you should be able to:

- Use the `bao` command-line tool with `BAO_ADDR` and `BAO_TOKEN`.
- Enable an auth method at a custom path and tune its lease limits with `bao auth tune`.
- Create a `userpass` user with `token_*` fields and log in with it.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **OpenBao v2.7.1**, initialized and unsealed, and the `bao` command-line tool on your PATH. The lab-only root token is in the Secret `openbao-init` in the namespace `openbao`.
- A `tester` pod in the namespace `clients`, with `curl` and `jq`.
- The KV engine `secret/` with example secrets and the policy `inventory-read`.

Nothing the task asks you to create has been created for you.

## Working rules

- Start the port-forward in a second terminal and set the address:
  `kubectl -n openbao port-forward svc/openbao 8200:8200`, then
  `export BAO_ADDR=http://openbao.localtest.me:8200`.
- Everything is graded on the **final state** of OpenBao, so leave your fix in place.
- Test with a real login before you submit.

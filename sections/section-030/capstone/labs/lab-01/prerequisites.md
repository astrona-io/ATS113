# Prerequisites

Before starting this lab you should be able to:

- Configure the JWT/OIDC auth method and its roles.
- Decode a JWT and compare its `iss`, `aud` and `groups` claims with the configuration.
- Manage userpass users.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **OpenBao v2.7.1**, initialized and unsealed, and the `bao` command-line tool on your PATH. The lab-only root token is in the Secret `openbao-init` in the namespace `openbao`.
- A `tester` pod in the namespace `clients`, with `curl` and `jq`.
- Keycloak 26.8.1 at `http://keycloak.localtest.me:8080` with the realm `inventory`, `alice` (group `ops`) and `bob` (group `dev`).
- The userpass user `breakglass` with the password `breakglass-password` (lab-only).

Nothing the task asks you to create has been created for you.

## Working rules

- Start the port-forward in a second terminal and set the address:
  `kubectl -n openbao port-forward svc/openbao 8200:8200`, then
  `export BAO_ADDR=http://openbao.localtest.me:8200`.
- Everything is graded on the **final state** of OpenBao, so leave your fix in place.
- Change one thing at a time and test it with a real login.

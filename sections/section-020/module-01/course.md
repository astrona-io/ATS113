# Log Machines In Without Long-Lived Secrets

A CI pipeline needs a database password, so someone pastes an OpenBao token into the pipeline's settings. Months later the token still works, nobody remembers which policy it has, and three other pipelines copied it. Machine auth methods remove that pasted token: the machine proves who it is with something it already has, and gets a short-lived token each time it starts.

An **auth method** is a plugin, mounted at a path such as `auth/approle/`, that checks some proof of identity and returns a token. A **role** inside the auth method says who may log in and which policies their token gets. This module covers three auth methods built for machines.

The module has three parts. **AppRole For Jobs And Pipelines** covers the auth method for anything that can be given two values, a `role_id` and a `secret_id`. **Kubernetes Auth For Pods** lets a pod log in with its own ServiceAccount token, so nothing needs to be copied at all; a graded lab follows it. **TLS Certificate Auth** logs a client in with the certificate it already presents in the TLS handshake.

## Learning objectives

After this module you can:

- Create an AppRole role, read its `role_id`, generate a `secret_id` and log in with both.
- Limit a `secret_id` by lifetime, number of uses and network.
- Configure Kubernetes auth for an OpenBao server that runs in the same cluster.
- Bind a Kubernetes auth role to one ServiceAccount in one namespace, and prove another ServiceAccount is refused.
- Configure TLS certificate auth with a trusted CA and an allowed common name.
- Read the error OpenBao returns for a refused machine login.

## Before you start

You should know what a token, a policy and a token TTL are, and be able to run `bao` against OpenBao. You need Kubernetes basics: namespaces, ServiceAccounts, pods and `kubectl exec`.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1**, initialized and unsealed, and the `bao` command-line tool on your PATH. It holds:

| Object | What it is |
| --- | --- |
| Policies `inventory-app`, `ci-deploy`, `reporting` | Read `secret/data/inventory/*`, `secret/data/ci/*` and `secret/data/reports/*` |
| Pod `inventory-app` (namespace `inventory`) | Runs as the ServiceAccount `inventory` and has `curl` |
| Pod `tester` (namespace `clients`) | Has `curl`, `jq` and a client certificate with the common name `reporting-job` at `/certs` |
| TLS listener | OpenBao also listens with TLS at `https://openbao-0.openbao-internal.openbao.svc.cluster.local:8443` |
| Secret `client-tls` (namespace `clients`) | The client certificate, its key and the lab certificate authority (`ca.crt`) |

Start the port-forward in a second terminal (`kubectl -n openbao port-forward svc/openbao 8200:8200`) and set `BAO_ADDR` and `BAO_TOKEN` as the parts show.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

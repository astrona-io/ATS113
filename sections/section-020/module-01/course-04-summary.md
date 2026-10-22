# Summary

Machines cannot type passwords, so OpenBao gives them auth methods that check something the machine already has, and return a short-lived token with a narrow policy. A role inside each auth method decides who may log in and which policies the token gets.

AppRole splits a machine's credential into a public `role_id` and a secret `secret_id`. The `role_id` can live in the job's configuration, while the `secret_id` is delivered separately and can be limited by lifetime, number of uses and network. A refused `secret_id` does not say which limit failed, so the role's settings are the first thing to read.

Kubernetes auth lets a pod log in with its ServiceAccount token. OpenBao asks the API server to review the token with the TokenReview API, which needs the ClusterRole `system:auth-delegator`, and then checks the ServiceAccount name and namespace against the role. When OpenBao runs in the cluster, its configuration needs only the API server's address. A role bound to one ServiceAccount in one namespace keeps every other pod out, and testing a refused login is as important as testing a working one.

TLS certificate auth logs a client in with the certificate it presents in the TLS handshake, so it only works on a listener with TLS. A certificate role trusts a CA and should also limit the common name or another field of the certificate.

- AppRole: deliver `role_id` and `secret_id` through different channels, and give the `secret_id` a TTL.
- Kubernetes auth: name both the ServiceAccount and the namespace, never `*`.
- Certificate auth: TLS listener, trusted CA, and a constraint such as `allowed_common_names`.

<!-- astrona:playground:destroy -->

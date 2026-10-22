# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Authentication for machines

## Scenario

Three machines stopped being able to log in after a configuration change:

- the `inventory-app` pod (ServiceAccount `inventory`, namespace `inventory`), through the Kubernetes auth role `inventory`;
- the CI job, through the AppRole role `ci`, with the credentials in the Secret `ci-approle` in `clients`;
- the reporting job in the `tester` pod, through the certificate role `reporting`, with the client certificate at `/certs` (`CN=reporting-job`).

Each auth method has one mistake. Your job is to find and fix all three.

## Your task

1. Make the `inventory-app` pod log in again with the role `inventory` and get `inventory-app`.
2. Make the CI job log in again from the `tester` pod with the `role_id` and `secret_id` in `ci-approle`, and get `ci-deploy`. If you generate a new `secret_id`, store it in `ci-approle`.
3. Make the reporting job log in again with its client certificate on the TLS listener (`https://openbao-0.openbao-internal.openbao.svc.cluster.local:8443`) and get `reporting`.

## Constraints

- The Kubernetes role must stay bound to the ServiceAccount `inventory` in the namespace `inventory` only.
- The certificate role must accept only the common name `reporting-job`.
- Do not give any role the `root` policy.

## Done when

- All three logins return a token with their own policy.
- The Kubernetes role names exactly `inventory` for both the ServiceAccount and the namespace.
- The certificate role's `allowed_common_names` is exactly `reporting-job`.

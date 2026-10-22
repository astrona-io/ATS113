# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Authentication for machines

## Scenario

The inventory application runs in the namespace `inventory` as the ServiceAccount `inventory`. It needs the policy `inventory-app`. A deployment job in the CI system needs the policy `ci-deploy`. Today both use tokens pasted by hand. The auth methods `kubernetes/` and `approle/` are already enabled, but nothing is configured in them.

## Your task

1. Configure the Kubernetes auth method so OpenBao can review ServiceAccount tokens from this cluster.
2. Create the Kubernetes auth role `inventory`:
   - bound to the ServiceAccount `inventory` in the namespace `inventory` only;
   - giving the policy `inventory-app`;
   - with a token TTL of 1 hour.
3. Create the AppRole role `ci`:
   - giving the policy `ci-deploy`;
   - with a token TTL of 20 minutes and a token max TTL of 30 minutes;
   - with a `secret_id` TTL of 24 hours.
4. Store the role's `role_id` and one `secret_id` in the Secret `ci-approle` in the namespace `clients`, under the keys `role_id` and `secret_id`.

## Constraints

- Do not bind the Kubernetes role to `*` for names or namespaces.
- Do not give either role the `root` policy or any policy other than its own.
- Do not change the policies.

## Done when

- The `inventory-app` pod logs in with Kubernetes auth and the role `inventory`, and gets `inventory-app`.
- A token of the ServiceAccount `default` in `inventory` is refused by the role `inventory`.
- The `role_id` and `secret_id` in `ci-approle` log in and give `ci-deploy`, with a token TTL of at most 20 minutes.

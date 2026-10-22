# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Tokens

## Scenario

The inventory service reads its database password from `secret/inventory/db` when it starts, and it runs for months. Today it uses a token an administrator created by hand with the root token, and nobody knows when that token will expire. You are asked to give the service a proper token.

## Your task

1. Create a token for the inventory service that:
   - has the policy `inventory-read`, and never `root`;
   - is a **periodic** token with a period of **24 hours**;
   - is an **orphan** token, so it does not depend on the token that created it;
   - is a **service** token (renewable), not a batch token.
2. Store the token in a Kubernetes Secret named `inventory-service-token` in the namespace `clients`, under the key `token`.

## Constraints

- Do not give the token the `root` policy or any policy other than `inventory-read` and `default`.
- Do not use an explicit max TTL: the service must be able to run as long as it renews.
- Leave the policy `inventory-read` as it is.

## Done when

- The token in `inventory-service-token` is an orphan service token with a period of 24 hours and the policy `inventory-read`.
- The token renews itself back to a TTL of 24 hours.
- The token can read `secret/inventory/db` and is refused `secret/reports/q3`.

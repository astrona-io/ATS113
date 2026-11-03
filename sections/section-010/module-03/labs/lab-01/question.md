# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Response wrapping and the cubbyhole

## Scenario

The inventory service is being deployed. Its database secret must reach the deployment job without appearing in a ticket or a log, and the service needs a token of its own with a short note waiting in its private storage.

## Your task

1. Create a wrapping token for the response of reading `secret/inventory/db`, with a wrapping TTL of **1 hour**. Store it in a Kubernetes Secret named `inventory-wrapped` in the namespace `clients`, under the key `token`.
2. Create a token with the policy `inventory-read` and no other policy except `default`. Using **that token**, write the key `text` with the value `ready` to the path `cubbyhole/deploy-note`.
3. Store the token in a Kubernetes Secret named `inventory-service-token` in the namespace `clients`, under the key `token`.

## Constraints

- Do not unwrap the wrapping token. The grader needs it unused.
- Do not store the plain password in any Secret.
- Do not give the service token the `root` policy.

## Done when

- A lookup of the stored wrapping token shows the creation path `secret/data/inventory/db` and a creation TTL of 1 hour.
- The service token carries `inventory-read`, reads `secret/inventory/db`, is refused `secret/reports/q3` and reads `cubbyhole/deploy-note`.
- The root token cannot read `cubbyhole/deploy-note`.

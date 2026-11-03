# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** AppRole

## Scenario

A deployment job in the CI system needs to log in to OpenBao with AppRole. The security team does not want any person to see its `secret_id`. A small provisioning program, the orchestrator, will create the `secret_id` and hand it over wrapped.

## Your task

1. Create the AppRole role `deploy` with:
   - the policy `ci-deploy` and no other policy except `default`;
   - a token TTL of **10 minutes** and a token max TTL of **20 minutes**;
   - a `secret_id` TTL of **15 minutes** and a `secret_id` that can be used **once**.
2. Write the policy `deploy-orchestrator`. It may read `auth/approle/role/deploy/role-id` and create a `secret_id` at `auth/approle/role/deploy/secret-id`. It may do nothing else.
3. Create a token with the policy `deploy-orchestrator`. Using that token, create a `secret_id` for the role `deploy` as a wrapping token with a wrapping TTL of **2 hours**.
4. Store the wrapping token in a Kubernetes Secret named `deploy-wrapped-secret-id` in the namespace `clients`, under the key `token`.

## Constraints

- Do not unwrap the wrapping token. The grader needs it unused.
- Do not use the root token to create the wrapped `secret_id`.
- Do not set `bind_secret_id` to `false`.
- Do not change the policy `ci-deploy`.

## Done when

- The role `deploy` has the settings above.
- The orchestrator policy allows exactly the two requests above and refuses reading the role, changing the role ID and reading secrets.
- The stored token is an unused wrapping token for a `secret_id` of the role `deploy`, with a 2 hour wrapping TTL.

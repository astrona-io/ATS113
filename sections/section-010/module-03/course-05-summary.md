# Summary

Every token has a cubbyhole, a private key-value store at `cubbyhole/` that no other token can read, not even the root token. It lives and dies with its token, so it holds short-lived working data and nothing that must last.

Response wrapping stores any response in the cubbyhole of a new wrapping token and returns only that token. The wrapping token works exactly once, so a second use shows that someone else opened the response. A wrapping TTL limits how long the token stays valid, and an unused token expires with its stored response.

Three endpoints under `sys/wrapping/` handle a wrapping token without needing the content. Lookup shows the creation path, creation time and TTL and does not use the token up. Rewrap moves the data into a new token with a fresh TTL and invalidates the old one. Wrap creates a wrapping token for data that you supply.

A safe delivery has an orchestrator that wraps, an untrusted channel that carries the wrapping token, and a receiver that looks the token up, compares the creation path, unwraps it once and raises an alert on any failure. The same flag also wraps a new token, so even the orchestrator never reads it.

- Unwrapping uses the token up; look it up when you only need to check it.
- A failed unwrap that you did not cause means the secret is exposed.
- Choose the shortest wrapping TTL that fits the delivery.

<!-- astrona:playground:destroy -->

# Summary

A production AppRole role is narrow on purpose. Its token has only the policies the job needs and a short TTL with a short maximum. Its `secret_id` expires soon, can be used once and can be bound to a network. The `bind_secret_id` setting stays on, because the `role_id` is not secret. The `role_id` can be set to a chosen value so that the job's configuration can exist before the role.

A `secret_id` comes into existence in pull mode, where OpenBao generates it and returns it once with an accessor, or in push mode, where the caller supplies it. Pull mode is preferred, because a pushed value is only as strong as its source. A creation request can narrow one `secret_id` further with a TTL, a use count, a network list and metadata that follows the login into the audit log.

To avoid showing the `secret_id` to anyone but the job, an orchestrator with a narrow policy creates it with a wrapping TTL. The policy allows reading one role's `role_id` and creating its `secret_id`, nothing else. The job unwraps the wrapping token once, and a failed unwrap means the token was used by someone else.

Accessors let an operator manage `secret_id` values without seeing them. Listing shows what exists, lookup shows the metadata and the uses left, and destroy ends a `secret_id` at once. Tokens that were already issued stay valid until their TTL, so a stolen `secret_id` needs a token revocation as well. The tidy endpoint removes expired entries.

- One role per job, with the smallest policy and the shortest TTLs that work.
- Create `secret_id` values through a narrow orchestrator, wrapped.
- Attach metadata, and destroy by accessor.

<!-- astrona:playground:destroy -->

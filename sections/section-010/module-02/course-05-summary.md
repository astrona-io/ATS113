# Summary

An auth method is a plugin mounted at a path below `auth/`. The same method can be mounted more than once, and each mount has its own users or roles, its own settings and its own accessor. The accessor identifies the mount in audit logs and in the identity system, so it is the safest way to tell mounts apart.

Disabling a mount is final. OpenBao deletes its configuration and users and revokes every token it issued, so live sessions stop at once. The built-in `token` method cannot be disabled.

A mount has its own lease limits. The default lease TTL applies when a user or role does not set a TTL, and the max lease TTL caps every token from the mount. The mount also sets the default token type and whether it shows in the unauthenticated listing. A tune changes new logins and renewals, not tokens that already exist.

Every auth method accepts the same `token_*` fields on its users or roles: policies, TTL, max TTL, period, number of uses, bound networks and token type. The mount's limits win over the user's values, so the real lease of a token is the smaller of what the user asks for and what the mount allows. `bao login` stores the token for later commands, and policies on `sys/auth` and `auth/<mount>/*` decide who can administer which mount.

- Read `bao auth list -detailed` before you disable anything.
- Use the `token_*` field names, not the deprecated `policies`, `ttl` and `max_ttl`.
- Check a real login's `lease_duration` to see what the mount did to your settings.

<!-- astrona:playground:destroy -->

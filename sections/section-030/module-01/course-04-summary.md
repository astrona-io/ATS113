# Summary

People need logins that follow them through the company, so OpenBao trusts an identity provider instead of keeping accounts for everyone. Userpass still has a place: a few local accounts, such as a break-glass account, that work when the identity provider does not. A userpass user's policies and password are changed through separate endpoints, and a password change does not end existing sessions.

The JWT/OIDC auth method is configured from the identity provider's discovery document and a client registered there. An OIDC role runs the browser login, and its redirect URIs must be listed both in the role and in the provider's client. The CLI uses a local listener on port 8250, and the web user interface uses a callback path under `/ui/vault/`. The issuer in every token must match the configuration, so the browser and OpenBao must reach the provider by the same name.

A JWT role checks an ID token that the client sends directly. `bound_audiences` makes sure the token was made for OpenBao's client, `user_claim` names the user, `groups_claim` names the groups, and `bound_claims` requires values such as the group `ops`. When a login is refused, OpenBao's error names the check, and decoding the token's claims shows the value that failed it. Login MFA can add a second factor for selected auth mounts or groups.

- Keep userpass for break-glass accounts only.
- Discovery URL = the issuer of the realm.
- Always set `bound_audiences`, and `bound_claims` for any role with a powerful policy.
- Decode the ID token's claims before changing the role.

<!-- astrona:playground:destroy -->

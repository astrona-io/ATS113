# Section 030: Authentication For People

People should not share tokens, and they should not get a second password just for OpenBao. Most companies already have an identity provider that knows who works there and which teams they belong to. This section connects OpenBao to one, Keycloak, through OpenID Connect, and keeps a small local userpass account for the day the identity provider is down.

## What you will learn

- Userpass accounts: creating them, logging in, and when a local account still makes sense.
- The JWT/OIDC auth method: configuring it from Keycloak's discovery document.
- OIDC roles for the browser and the `bao login -method=oidc` flow, with its redirect URIs.
- JWT roles for automation, with `bound_audiences`, `user_claim`, `groups_claim` and `bound_claims`.
- Reading the claims in an ID token to find why a login is refused.
- What login multi-factor authentication (MFA) adds.

## The learning path

The module starts at its landing page, which also launches the playground. The playground holds OpenBao and Keycloak 26.8.1 with the realm `inventory`, the users `alice` (group `ops`) and `bob` (group `dev`), and the client `openbao`.

### 1. Log People In With Userpass And Keycloak

1. Userpass Accounts
2. OIDC Login With Keycloak
3. JWT Roles, Bound Claims And Login MFA, followed by the lab **Map A Keycloak Group To An OpenBao Policy**
4. Summary

## Section capstone: Repair A Broken Keycloak Login

Nobody from the ops team can log in through Keycloak anymore, and the break-glass account that should save the day has no useful policy. Three settings in the auth method and one on the account are wrong. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS113.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-113-capstone-030
```

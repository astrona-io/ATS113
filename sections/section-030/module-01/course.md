# Log People In With Userpass And Keycloak

A new engineer joins the ops team. In Keycloak, someone adds them to the group `ops`. If OpenBao trusts Keycloak, the engineer can log in to OpenBao the same afternoon, with the ops policy, and loses access the day they leave the group. Nobody had to create an OpenBao account for them. That is the goal of this module.

**OpenID Connect (OIDC)** is a standard way for an application to ask an identity provider who a user is. The identity provider answers with an **ID token**, a signed JSON Web Token (JWT) that holds **claims** about the user, such as their user name and groups. OpenBao's **JWT/OIDC auth method** checks such tokens and turns them into OpenBao tokens.

The module has three parts. **Userpass Accounts** covers local user names and passwords, the simplest login for people and the one to keep for emergencies. **OIDC Login With Keycloak** configures the JWT/OIDC auth method from Keycloak and logs a person in through the browser. **JWT Roles, Bound Claims And Login MFA** shows the roles that check an ID token sent directly, which is how automation and the labs log in, and how to require a group; a graded lab follows it.

## Learning objectives

After this module you can:

- Create a userpass account with a policy and log in with it.
- Configure the JWT/OIDC auth method from an identity provider's discovery document.
- Write an OIDC role with the redirect URIs for the CLI and the web user interface.
- Log in with `bao login -method=oidc`.
- Write a JWT role with `bound_audiences`, `user_claim`, `groups_claim` and `bound_claims`.
- Decode an ID token and compare its claims with a role to explain a refused login.

## Before you start

You should know what a token, a policy and an auth method role are, and be able to run `bao` against OpenBao. You do not need to know Keycloak; the pages show every Keycloak value you need.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1**, initialized and unsealed, and **Keycloak 26.8.1**. It holds:

| Object | What it is |
| --- | --- |
| Keycloak realm `inventory` | At `http://keycloak.localtest.me:8080/realms/inventory` |
| Users `alice`, `bob` | `alice` is in the group `ops`, `bob` in `dev`; passwords `alice-password` and `bob-password` (lab-only) |
| Client `openbao` | Confidential client with the secret `openbao-client-secret`; its ID tokens carry a `groups` claim |
| Policies `ops`, `dev`, `breakglass` | Read `secret/data/ops/*`, `secret/data/dev/*`, and the policy list |

Start two port-forwards in a second terminal, one for OpenBao and one for Keycloak:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200 &
kubectl -n keycloak port-forward svc/keycloak 8080:8080 &
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

# Userpass Accounts

The identity provider is down, and an incident is in progress. Someone must still be able to log in to OpenBao. Userpass, the simplest auth method for people, is the usual answer: a few local accounts, kept for emergencies, that work when nothing else does.

## User names and passwords in OpenBao

**Userpass** is an auth method that stores user names and password hashes in OpenBao itself. Each user has its own token settings, such as policies and TTL. It is easy to set up, but it does not scale: every account must be created, changed and removed in OpenBao by hand, and OpenBao knows nothing about teams. So keep userpass for a small number of accounts, such as a break-glass account for emergencies.

Enable it and create one account:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao auth enable userpass
bao write auth/userpass/users/breakglass password=breakglass-password token_policies=breakglass token_ttl=1h
```

The user's settings live at `auth/userpass/users/breakglass`. OpenBao stores a hash of the password, never the password itself.

## Log in as the user

Logging in with `bao login` stores the new token for the `bao` command-line tool. Run the login in a subshell, so your own root token in `BAO_TOKEN` stays as it is:

```sh
(unset BAO_TOKEN; bao login -method=userpass username=breakglass password=breakglass-password)
```

OpenBao answers with the new token, its policies `default` and `breakglass`, and a duration of one hour. Typing a password on the command line leaves it in your shell history; leave out `password=...` and `bao` asks for it without showing it.

## Change an account

The settings of a user can be changed without touching the password, and the password can be changed without touching the settings:

```sh
bao write auth/userpass/users/breakglass/policies token_policies=breakglass,ops
bao write auth/userpass/users/breakglass/password password=a-new-breakglass-password
bao read auth/userpass/users/breakglass
```

The read shows the policies and TTL, but never the password. Changing the password does not revoke tokens the user already has; revoke them separately if the password leaked.

You now know how to keep a local account in OpenBao and when it is the right tool. For everyone else, the accounts should come from an identity provider.

## Common pitfalls

> [!WARNING]
> - **Using userpass for the whole company.** Accounts in OpenBao do not follow people who change teams or leave. Use an identity provider.
> - **Passwords in shell history.** Let `bao login` ask for the password.
> - **A typo in the user name.** `bao write auth/userpass/users/<name>` creates the user if it does not exist, so a typo creates a second account instead of changing the first. Read the user back after every change.
> - **Expecting a password change to end old sessions.** It does not. Revoke the old tokens.

# Log In From The CLI And Delegate Administration

Setting up a mount is an administrator task, and logging in is a user task. Both need the right commands, and the first needs a policy that gives a team control of its own mount without giving it control of the server. This part covers the login commands and the policy paths that guard auth methods.

## Log in with bao login

`bao write auth/staff/login/alice password=...` works, but it prints the whole response and does not keep the token. The command `bao login` is made for people: it sends the login request, then saves the returned token in the token helper file `~/.vault-token` so that later `bao` commands use it. Pass the method and the path of the mount:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao auth enable -path=staff userpass
bao write auth/staff/users/alice password=alice-password token_policies=inventory-read
unset BAO_TOKEN
bao login -method=userpass -path=staff username=alice password=alice-password
```

`-path=staff` is needed because the mount is not at the default `userpass/` path. The command prints the token and its policies and stores it. A password given on the command line stays in the shell history, so people should leave `password=` out; `bao login` then asks for it without echoing it.

Two flags help in scripts. `-no-store` prints the token without writing it to the token helper, and `-token-only` prints only the token value:

```sh
STAFF_TOKEN=$(bao login -method=userpass -path=staff -no-store -token-only username=alice password=alice-password)
BAO_TOKEN=$STAFF_TOKEN bao token lookup
```

The lookup shows the `path` field `auth/staff/login/alice`, which records the mount and the user that issued the token.

## Policy paths for auth methods

Managing auth methods is controlled by the same ACL policies as secrets, through a few system paths:

| Path | What it allows |
| --- | --- |
| `sys/auth` | List all auth mounts (`read`) |
| `sys/auth/<mount>` | Enable (`create`, `sudo`) and disable (`delete`, `sudo`) one mount |
| `sys/auth/<mount>/tune` | Tune one mount (`update`) |
| `auth/<mount>/*` | Manage the users or roles inside one mount |

Enabling and disabling a mount needs the `sudo` capability on top of the usual one, because both change the server's structure.

A team that runs the `staff` mount needs to manage its users, but not mount or unmount anything. Save this as `staff-admin.hcl`:

```hcl
path "auth/staff/users/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "sys/auth" {
  capabilities = ["read"]
}
```

Write the policy with the root token and test it with a token that carries it:

```sh
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao policy write staff-admin staff-admin.hcl
ADMIN_TOKEN=$(bao token create -policy=staff-admin -field=token)
BAO_TOKEN=$ADMIN_TOKEN bao write auth/staff/users/bob password=bob-password token_policies=inventory-read
BAO_TOKEN=$ADMIN_TOKEN bao auth disable staff
```

The user is created. The disable is refused with `permission denied`, because the policy has no capability on `sys/auth/staff`. The team can manage its users and nothing more.

You now know how to log in from the command line and how to give a team control of one mount. The remaining question is what to check when a login does not work, and the answer is in the three places you used in this module: the mount path, the mount's settings and the user's `token_*` fields.

## Common pitfalls

> [!WARNING]
> - **Passing `password=` on the command line for a real account.** It stays in the shell history. Let `bao login` ask for it.
> - **Leaving a token in `~/.vault-token` and then testing as another user.** The old token is used. Run `bao token lookup` to see who you are.
> - **Granting `sys/auth/*` to a team.** That allows tuning and, with `sudo`, disabling any mount. Name the mount path.
> - **Forgetting `-path` for a mount at a custom path.** `bao login` then tries `auth/userpass/` and the login fails.

# Token Settings On Logins

A login proves who someone is. The token that comes back says what they may do and for how long. Every auth method shares one set of fields for this second half, so once you know them for `userpass`, you know them for AppRole, LDAP, Kubernetes and the rest. The names start with `token_`.

## The token fields

When an auth method creates a token, it takes the settings from the user or role that matched the login. These `token_*` fields work the same on every method:

| Field | What it sets |
| --- | --- |
| `token_policies` | The policies attached to the token (OpenBao also adds `default`) |
| `token_ttl` | The starting TTL of the token |
| `token_max_ttl` | The longest the token can live, counting renewals |
| `token_explicit_max_ttl` | A hard limit that also applies to periodic tokens |
| `token_period` | Makes the token periodic, with this renewal period |
| `token_num_uses` | How many requests the token can make (0 means unlimited) |
| `token_bound_cidrs` | The client networks that can use the token |
| `token_type` | `service` or `batch` (or `default` to use the mount's setting) |
| `token_no_default_policy` | Leaves the `default` policy off the token |

Older documentation and some methods also accept `policies`, `ttl` and `max_ttl`. These are deprecated aliases. Use the `token_*` names.

## Create a user and watch the fields work

Create a mount, then a user with explicit limits, and log in:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao auth enable -path=staff userpass
bao write auth/staff/users/alice password=alice-password \
  token_policies=inventory-read token_ttl=30m token_max_ttl=1h
bao write auth/staff/login/alice password=alice-password
```

The response has an `auth` block with `policies` set to `default` and `inventory-read`, a `lease_duration` of `1800` seconds and `renewable` set to `true`. The `token_ttl` of 30 minutes became the first lease, and `token_max_ttl` is the ceiling for renewals.

Read the user back to see how OpenBao stored the fields:

```sh
bao read auth/staff/users/alice
```

The output lists `token_policies`, `token_ttl` and `token_max_ttl` with the values you set, and the other `token_*` fields at their defaults.

## Network binding and use limits

`token_bound_cidrs` limits where the token can be used from. A **CIDR** (Classless Inter-Domain Routing) block such as `10.0.0.0/8` names a range of IP addresses. When the field is set, OpenBao refuses requests with that token from any other address. Use it for service accounts that always run in a known network:

```sh
bao write auth/staff/users/alice token_bound_cidrs=10.0.0.0/8
bao write auth/staff/login/alice password=alice-password
```

OpenBao refuses the login, because the request comes from an address outside `10.0.0.0/8`: the CIDR check also applies to the login. Remove the binding by writing an empty value:

```sh
bao write auth/staff/users/alice token_bound_cidrs=""
```

`token_num_uses` works the other way: after the given number of requests, the token is revoked. A value of `1` suits a token that is only used to fetch one secret.

## How the mount and the user combine

The user's `token_ttl` is used when it is set, and the mount's default lease TTL is used when it is not. In both cases the mount's max lease TTL is a hard cap. A user with `token_ttl=12h` on a mount with a max lease TTL of `8h` gets an 8 hour token.

```sh
bao auth tune -max-lease-ttl=8h auth/staff
bao write auth/staff/users/alice token_ttl=12h token_max_ttl=24h
bao write -format=json auth/staff/login/alice password=alice-password | jq '.auth.lease_duration'
```

The result is `28800`, eight hours in seconds, not the twelve hours that the user asked for.

You can now set the whole lifetime and scope of a login on the user or role, and predict what the mount does to it. Writing these fields correctly on a new mount is the first skill the graded lab checks.

## Common pitfalls

> [!WARNING]
> - **Writing a user without `token_policies`.** The token gets only the `default` policy and every request for a secret returns `permission denied`.
> - **Using the deprecated `policies` field in new configuration.** It still works on some methods, but the `token_*` names are the ones that every method documents.
> - **Setting `token_bound_cidrs` to a range the client is not in.** The login is refused. Test from the machine that will log in.
> - **Expecting `token_ttl` to beat the mount's max lease TTL.** The mount's limit wins. Read the `lease_duration` of a real login.

## Your mission: Set Up A Tuned Staff Login

You can now mount an auth method at a custom path, tune its lease limits and give a user precise token settings. The graded lab asks you to build a staff login for a user who needs read access to inventory secrets, with token limits the security team has set.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-113-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS113.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-113-lab-010-02
astrona start ats-113-playground-010-02
```

# Lookup, Rewrap And Wrap Your Own Data

A wrapping token is useful only if the receiver can trust it. The receiver wants to know where the token came from and how long it lives, and wants to find out without opening it. The sender sometimes wants to extend a token that is about to expire. OpenBao has three endpoints under `sys/wrapping/` for these jobs, and a fourth that wraps data you provide.

## Look up a wrapping token

The **lookup** endpoint tells you about a wrapping token and does not use it up. It returns the creation time, the creation TTL and the creation path, which is the request that was wrapped. Anyone can call it, even without a token, because it only reveals metadata:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
WRAPPING_TOKEN=$(bao kv get -wrap-ttl=30m -field=wrapping_token secret/inventory/db)
bao write sys/wrapping/lookup token=$WRAPPING_TOKEN
```

The output shows `creation_path` as `secret/data/inventory/db`, `creation_ttl` as `30m` and the creation time. A receiver compares the creation path with the one it expects. A wrapping token that someone made for a different path, or that an attacker made with their own data, has a different path and the receiver refuses it.

The lookup fails for a token that was already used or has expired. That is useful too, because it answers "is this still valid?" before the receiver does anything else.

## Rewrap a wrapping token

The **rewrap** endpoint moves the wrapped data into a new wrapping token and invalidates the old one. The new token gets a fresh TTL. The data is never revealed to the caller, so a person who handles the token cannot read the secret. Rotate the token this way when it is about to expire and the receiver is not ready:

```sh
bao write sys/wrapping/rewrap token=$WRAPPING_TOKEN
```

The output contains a new `wrapping_token`. The old one no longer works, so lookup of the old token now fails.

## Wrap your own data

Some data does not come from a read. An administrator might receive an API key from a vendor and want to pass it on once. The endpoint `sys/wrapping/wrap` takes any key-value pairs and returns a wrapping token for them:

```sh
bao write -wrap-ttl=10m sys/wrapping/wrap vendor-key=abc123
```

The command returns a wrapping token whose creation path is `sys/wrapping/wrap`. Unwrap it once to see the data:

```sh
NEW_TOKEN=$(bao write -wrap-ttl=10m -field=wrapping_token sys/wrapping/wrap vendor-key=abc123)
bao unwrap $NEW_TOKEN
```

The unwrap prints `vendor-key` with its value. The same procedure covers any short-lived value that has to travel between people.

## Which endpoint does what

| Endpoint | What it does | Uses the token up |
| --- | --- | --- |
| `sys/wrapping/lookup` | Shows creation path, creation time and TTL | No |
| `sys/wrapping/unwrap` | Returns the wrapped response | Yes |
| `sys/wrapping/rewrap` | Moves the data into a new wrapping token | The old one |
| `sys/wrapping/wrap` | Wraps data that you supply | Not applicable |

You can now inspect, extend and create wrapping tokens. What is left is the delivery itself, who takes each role, and what the receiver should do when something is wrong. The graded lab asks you to build a small delivery now.

## Common pitfalls

> [!WARNING]
> - **Treating a successful lookup as proof that the content is right.** It proves the creation path and TTL. Check that the creation path is the one you expect.
> - **Rewrapping to extend the life of a leaked token.** The new token also has the leaked data. If the wrapping token may be in the wrong hands, wrap the secret again from the source instead.
> - **Wrapping data with `sys/wrapping/wrap` and logging the command.** The data appears in the command history. Pass it from a file or a variable.

## Your mission: Deliver A Secret With A Wrapping Token

You can now wrap a read, check a wrapping token without opening it and use the cubbyhole. The graded lab asks you to prepare a delivery for the inventory service: a wrapping token for its database secret, and a service token with a private note in its cubbyhole.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-113-playground-010-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS113.git -c sections/section-010/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-113-lab-010-03
astrona start ats-113-playground-010-03
```

# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Authentication methods

## Scenario

The security team wants staff to log in to OpenBao with a user name and password instead of sharing tokens. Staff sessions must be short, and the login method must be mounted at its own path so that a later contractor login can use a different mount. Alice from the inventory team is the first user.

## Your task

1. Enable a `userpass` auth method at the path `staff`, with the description `Logins for staff`.
2. Tune the mount so that the default lease TTL is **2 hours** and the max lease TTL is **8 hours**.
3. Create the user `alice` at that mount with the password `alice-password`, the policy `inventory-read`, a token TTL of **30 minutes** and a token max TTL of **1 hour**.

## Constraints

- Do not enable `userpass` at its default path `userpass/`.
- Do not give the user any policy other than `inventory-read`, and never `root`.
- Do not change the policy `inventory-read`.

## Done when

- `auth/staff/` is a `userpass` mount with the lease limits above.
- Alice logs in at `auth/staff/login/alice` and gets a token with `inventory-read` and a lease of 30 minutes.
- Her token reads `secret/inventory/db` and is refused `secret/reports/q3`.

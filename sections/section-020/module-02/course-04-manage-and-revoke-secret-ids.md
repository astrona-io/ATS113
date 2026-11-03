# Manage And Revoke Secret IDs

Creating a `secret_id` is half of its life. The other half is knowing which ones exist, finding out where one came from, and destroying one that should not be valid any more. OpenBao identifies each `secret_id` by an accessor so you can do all of this without ever handling the secret value.

## List the secret IDs of a role

Every `secret_id` a role has issued and not yet spent or expired has an accessor. Create three and list them:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao write auth/approle/role/deploy token_policies=ci-deploy token_ttl=10m token_max_ttl=20m secret_id_ttl=1h
bao write auth/approle/role/deploy/secret-id metadata='{"build":"101"}'
bao write auth/approle/role/deploy/secret-id metadata='{"build":"102"}'
bao write auth/approle/role/deploy/secret-id metadata='{"build":"103"}'
bao list auth/approle/role/deploy/secret-id
```

The list prints three accessors. An **accessor** is an ID that names a `secret_id` for administration. It cannot be used to log in.

## Look up one secret ID

Read one accessor's details with the lookup endpoint. Take the first accessor from the list:

```sh
ACCESSOR=$(bao list -format=json auth/approle/role/deploy/secret-id | jq -r '.[0]')
bao write auth/approle/role/deploy/secret-id-accessor/lookup secret_id_accessor=$ACCESSOR
```

The output shows the creation time, the expiration time, the number of uses left and the `metadata` that you attached. The metadata is how you find the build or the person behind a `secret_id`.

If you still have the secret value, you can look it up with `secret-id/lookup` and the field `secret_id`. Prefer the accessor: it works when the value is gone.

## Destroy a secret ID

To revoke a `secret_id` before it expires, destroy it by accessor. Logins with it stop at once, and tokens that came from earlier logins stay valid until their own TTL:

```sh
bao write auth/approle/role/deploy/secret-id-accessor/destroy secret_id_accessor=$ACCESSOR
bao list auth/approle/role/deploy/secret-id
```

The list now has two accessors. When you hold the value instead, destroy with `secret-id/destroy` and the field `secret_id`.

To stop everything that a role has issued, delete the role. The role's `secret_id` values are deleted with it, but tokens already issued remain until they expire; revoke those separately with `bao token revoke`.

```sh
bao delete auth/approle/role/deploy
```

## Clean up expired entries

Expired `secret_id` entries stay in storage until OpenBao removes them. The tidy endpoint removes expired entries and the accessors that point to nothing:

```sh
bao write -f auth/approle/tidy/secret-id
```

OpenBao runs the cleanup in the background, and the response says so. Run it from a schedule on a busy server.

You now have all the pieces of a production AppRole setup: a narrow role, a controlled way to create a `secret_id`, a wrapped delivery and a way to find and destroy values. The troubleshooting step that remains is reading the refusal you get when one piece is wrong: check the `role_id`, then the `secret_id` state, then the network limits, in that order.

## Common pitfalls

> [!WARNING]
> - **Destroying a `secret_id` and expecting its token to die.** The token lives until its TTL. Revoke it as well when the `secret_id` was stolen.
> - **Deleting the role to remove one `secret_id`.** Destroy by accessor instead.
> - **Not attaching `metadata`.** Without it, you cannot tell which build or person created a `secret_id` you find in the list.
> - **Leaving tokens alive after a role is deleted.** They keep working until their TTL ends. Revoke them with `bao token revoke`.

# Pull And Push Secret IDs

A `secret_id` can come into existence in two ways. In the usual way, OpenBao creates it and hands it to whoever asks. In the other way, someone brings their own value and gives it to OpenBao. The two ways have different risks, and the choice decides who holds the secret before the job does.

## Pull mode: OpenBao generates it

In **pull mode**, a client with the right policy asks OpenBao to generate a `secret_id`. The value is random, and OpenBao shows it once. This is the mode you used in the previous part, and the one to prefer:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao write auth/approle/role/deploy token_policies=ci-deploy token_ttl=10m token_max_ttl=20m secret_id_ttl=15m secret_id_num_uses=1
bao write auth/approle/role/deploy/role-id role_id=deploy-job
bao write -f auth/approle/role/deploy/secret-id
```

The response has two fields: `secret_id`, the value the job will use, and `secret_id_accessor`, an ID that names this `secret_id` for lookup and destruction without revealing it. The response also shows `secret_id_ttl` and `secret_id_num_uses` taken from the role.

The create request accepts options that narrow this one `secret_id` below the role's limits. `ttl` and `num_uses` shorten the lifetime and the use count, `cidr_list` limits the networks, and `metadata` stores a JSON map that OpenBao attaches to the token and writes to the audit log:

```sh
bao write auth/approle/role/deploy/secret-id ttl=5m metadata='{"build":"4711","team":"ci"}'
```

The metadata ties a login back to the pipeline run that requested the `secret_id`. A value cannot be higher than the role's own limit.

## Push mode: you bring the value

In **push mode**, the caller chooses the `secret_id` and writes it to the `custom-secret-id` endpoint. It is meant for the case where another system already generates and stores identifiers, and OpenBao should accept them:

```sh
bao write auth/approle/role/deploy/custom-secret-id secret_id=my-own-secret-value
bao write auth/approle/login role_id=deploy-job secret_id=my-own-secret-value
```

The login works if the `role_id` is correct. The role's limits apply to a pushed value in the same way.

The weakness of push mode is that the value exists outside OpenBao before it is stored. Someone generated it, someone transported it, and the strength of the value depends on how it was generated. A short or guessable value is a weak credential, and OpenBao does not check the strength. Use push mode only when you must, with a long random value.

| | Pull mode | Push mode |
| --- | --- | --- |
| Endpoint | `secret-id` | `custom-secret-id` |
| Who generates the value | OpenBao | The caller |
| The value is returned | Once, in the response | Never; the caller already has it |
| Accessor in the response | Yes | Yes |

## Bind a secret ID to a network

Both modes accept `cidr_list` on the request and `secret_id_bound_cidrs` on the role. A login with a `secret_id` that is bound to a network is refused from any other address. A refused login does not name the failing rule, so a bound network is the first thing to check when a correct `secret_id` is refused.

```sh
bao write auth/approle/role/deploy/secret-id cidr_list=10.0.0.0/8
bao write auth/approle/login role_id=deploy-job secret_id=<SECRET_ID>
```

Replace `<SECRET_ID>` with the value from the first command. The login is refused, because the request does not come from `10.0.0.0/8`.

You can now create a `secret_id` in either mode and narrow it. What has not been solved yet is the delivery: whoever creates the `secret_id` sees it. The next part removes that exposure.

## Common pitfalls

> [!WARNING]
> - **Using push mode with a human-chosen value.** The value is only as strong as its source. Use a long random string.
> - **Asking for a `ttl` or `num_uses` above the role's limit.** The request fails or the role's limit applies. Read the response to see the real values.
> - **Losing the accessor.** Without it you can destroy the `secret_id` only if you still have the value.
> - **Using a CIDR that does not match the job's real address.** Every login is refused with an invalid `secret_id` error.

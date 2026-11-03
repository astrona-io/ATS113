# Solution: Issue Identity Tokens For Alice

Work the task yourself first. Running `astrona submit -c sections/section-040/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the entity's metadata and alias, the key and the role, and a real token read as Alice.

## Step 1: Connect to OpenBao

Start the port-forward in a second terminal, then set the address and the lab-only root token:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao read identity/entity/name/alice
```

The entity has an alias and empty metadata.

## Step 2: Add the metadata

```sh
bao write identity/entity name=alice metadata=team=inventory
bao read -format=json identity/entity/name/alice | jq '.data.metadata, .data.aliases | length'
```

The name stays the same, so the write updates the existing entity and the alias stays.

## Step 3: Create the key

```sh
bao write identity/oidc/key/inventory algorithm=RS256 rotation_period=24h verification_ttl=24h allowed_client_ids="*"
```

## Step 4: Create the role

Save this as `template.json`:

```json
{
  "team": {{identity.entity.metadata.team}},
  "name": {{identity.entity.name}}
}
```

```sh
bao write identity/oidc/role/inventory-reader key=inventory ttl=30m template=@template.json
```

## Step 5: Read a token as Alice

```sh
ALICE_TOKEN=$(bao write -field=token auth/userpass/login/alice password=alice-password)
JWT=$(BAO_TOKEN=$ALICE_TOKEN bao read -field=token identity/oidc/token/inventory-reader)
printf '%s' "$JWT" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
bao write identity/oidc/introspect token=$JWT
```

The payload has `team` as `inventory`, `name` as `alice`, `sub` as the entity ID, and `exp` 1800 seconds after `iat`. The introspection answer has `active` set to `true`.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Read the token with the root token | The root token has no entity, so there are no claims |
| Create a new entity named alice | The name is taken, and a second entity would not own the alias |
| Write `metadata=team=inventory` on a different entity | The login of alice still belongs to the entity `alice` and gets no `team` claim |
| Leave `allowed_client_ids` empty | The role's client ID is not allowed on the key |

## Common mistakes

- Putting quotes around the template values.
- Forgetting `ttl=30m` and getting the default of 24 hours.
- Reading the token before the metadata exists, which leaves the `team` claim empty.

# Solution: Give Alice One Identity Across Two Logins

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass.

## Step 1: Connect, and do not log in as alice yet

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200 &
kubectl -n keycloak port-forward svc/keycloak 8080:8080 &
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
USERPASS_ACCESSOR=$(bao auth list -format=json | jq -r '."userpass/".accessor')
OIDC_ACCESSOR=$(bao auth list -format=json | jq -r '."oidc/".accessor')
```

A login before the aliases exist would create a separate entity for that login. If that happens, merge it into `alice` with `identity/entity/merge`.

## Step 2: Create the entity and its aliases

```sh
bao write identity/entity name=alice metadata=team=ops
ALICE_ENTITY_ID=$(bao read -field=id identity/entity/name/alice)
bao write identity/entity-alias name=alice canonical_id=$ALICE_ENTITY_ID mount_accessor=$USERPASS_ACCESSOR
bao write identity/entity-alias name=alice canonical_id=$ALICE_ENTITY_ID mount_accessor=$OIDC_ACCESSOR
bao read identity/entity/name/alice
```

The entity shows two aliases, one per mount accessor. The JWT alias name is `alice` because the role's `user_claim` is `preferred_username`.

## Step 3: Create the internal group

```sh
bao write identity/group name=ops type=internal policies=ops-shared member_entity_ids=$ALICE_ENTITY_ID
```

## Step 4: Prove it

```sh
bao write -format=json auth/userpass/login/alice password=alice-password | jq -r .auth.entity_id
ALICE_ID_TOKEN=$(curl -s -X POST http://keycloak.localtest.me:8080/realms/inventory/protocol/openid-connect/token \
  -d grant_type=password -d client_id=openbao -d client_secret=openbao-client-secret \
  -d username=alice -d password=alice-password -d scope=openid | jq -r .id_token)
bao write -format=json auth/oidc/login role=person jwt=$ALICE_ID_TOKEN | jq '{entity_id: .auth.entity_id, identity_policies: .auth.identity_policies}'
echo $ALICE_ENTITY_ID
```

Both logins print the same entity ID as `$ALICE_ENTITY_ID`, and the JWT login shows `ops-shared` among its identity policies.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Add `ops-shared` to the userpass user | The grader checks the identity policies from the group |
| Log in first, then create a new entity named `alice` | The aliases already belong to generated entities; creating them again fails |
| An external group instead of an internal one | The task asks for members set in OpenBao |

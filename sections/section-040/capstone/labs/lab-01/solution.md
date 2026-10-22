# Solution: Make Groups From Keycloak Drive Access

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass.

## Step 1: Connect and collect the IDs

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200 &
kubectl -n keycloak port-forward svc/keycloak 8080:8080 &
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
ALICE_ENTITY_ID=$(kubectl -n clients get configmap capstone-baseline -o jsonpath='{.data.alice-entity-id}')
OIDC_ACCESSOR=$(bao auth list -format=json | jq -r '."oidc/".accessor')
```

## Step 2: Merge the duplicate entity

Find the entity that holds alice's alias on `oidc/`, and merge it into `alice`:

```sh
DUPLICATE_ID=$(bao write -format=json identity/lookup/entity alias_name=alice alias_mount_accessor=$OIDC_ACCESSOR | jq -r .data.id)
echo $DUPLICATE_ID $ALICE_ENTITY_ID
bao write identity/entity/merge from_entity_ids=$DUPLICATE_ID to_entity_id=$ALICE_ENTITY_ID
bao read identity/entity/name/alice
```

The duplicate had a generated name. After the merge, the entity `alice` shows both aliases and keeps its ID.

## Step 3: Fix the external group's alias

```sh
bao read identity/group/name/ops-external
```

The group's alias is named `Ops`, but the `groups` claim in Keycloak's ID tokens says `ops`. Names are compared exactly, so replace the alias:

```sh
OPS_GROUP_ID=$(bao read -field=id identity/group/name/ops-external)
OLD_ALIAS_ID=$(bao read -format=json identity/group/name/ops-external | jq -r .data.alias.id)
bao delete identity/group-alias/id/$OLD_ALIAS_ID
bao write identity/group-alias name=ops mount_accessor=$OIDC_ACCESSOR canonical_id=$OPS_GROUP_ID
```

## Step 4: Fix the template

```sh
bao policy read personal
```

The template uses `{{identity.entity.id}}`, but the folders are named after people. Save this as `policy-personal.hcl`:

```hcl
path "secret/data/users/{{identity.entity.name}}/*" {
  capabilities = ["create", "read", "update"]
}
```

Write it:

```sh
bao policy write personal policy-personal.hcl
```

## Step 5: Prove it

```sh
id_token_for() {
  curl -s -X POST http://keycloak.localtest.me:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=openbao -d client_secret=openbao-client-secret \
    -d username="$1" -d password="$1-password" -d scope=openid | jq -r .id_token
}
bao write -format=json auth/oidc/login role=person jwt=$(id_token_for alice) | jq '{entity_id: .auth.entity_id, identity_policies: .auth.identity_policies}'
ALICE_TOKEN=$(bao write -field=token auth/userpass/login/alice password=alice-password)
BAO_TOKEN=$ALICE_TOKEN bao kv put secret/users/alice/todo text="check the merge"
BAO_TOKEN=$ALICE_TOKEN bao kv get secret/users/bob/note
```

The JWT login returns alice's original entity ID and `ops-admin`; the write to her folder succeeds and the read of bob's note is refused.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the entity `alice` and let a login recreate it | The ID changes; the grader compares it with the baseline |
| Add alice to `ops-external` by hand | OpenBao manages external group members from logins; bob's tokens would still be checked |
| A policy on `secret/data/users/alice/*` | Works for alice only, and the grader requires a template |

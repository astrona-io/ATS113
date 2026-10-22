# Solution: Repair A Token Role For A Reporting Service

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

## Step 1: Read the role and its token

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao read auth/token/roles/reporting
LEAKED_ACCESSOR=$(kubectl -n clients get configmap leaked-token -o jsonpath='{.data.accessor}')
bao token lookup -accessor $LEAKED_ACCESSOR
```

The role shows three problems: `allowed_policies` contains `admin`, `orphan` is `false`, and `token_explicit_max_ttl` is one hour with no `token_period`. The leaked token's lookup shows it came from the role.

## Step 2: Fix the role

Write the role again with the settings you want. `token_explicit_max_ttl=0` removes the hard limit.

```sh
bao write auth/token/roles/reporting \
  allowed_policies=reporting orphan=true token_period=24h token_explicit_max_ttl=0
bao read auth/token/roles/reporting
bao token create -role=reporting -policy=admin
```

The read shows the new settings, and the last command is refused, because `admin` is no longer allowed.

## Step 3: Revoke the leaked token

Revoking by accessor works without ever holding the token itself:

```sh
bao token revoke -accessor $LEAKED_ACCESSOR
bao token lookup -accessor $LEAKED_ACCESSOR
```

The lookup now fails: the token is gone.

## Step 4: Issue and store a new token

```sh
REPORTING_TOKEN=$(bao token create -role=reporting -policy=reporting -field=token)
bao token lookup $REPORTING_TOKEN
kubectl -n clients delete secret reporting-token
kubectl -n clients create secret generic reporting-token --from-literal=token=$REPORTING_TOKEN
BAO_TOKEN=$REPORTING_TOKEN bao kv get secret/reports/q3
```

The lookup shows `role` as `reporting`, `orphan` as `true` and `period` as `24h`, and the read succeeds.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the role and create the token directly | The grader requires the token to come from the role |
| Keep `admin` in `allowed_policies` | Anyone who may use the role can still create an administrator token |
| Revoke the old token by pasting it from the Secret | It works here, but in real life you often have only the accessor; and the Secret holds a new token after Step 4 |

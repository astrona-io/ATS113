# Solution: Let The Inventory App And The CI Job Log In

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass.

## Step 1: Connect to OpenBao

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao auth list
```

`bao auth list` shows `kubernetes/` and `approle/` next to `token/`.

## Step 2: Configure Kubernetes auth and the role

OpenBao runs in the same cluster, so it uses its own ServiceAccount token and the cluster CA; only the API server's address is needed.

```sh
bao write auth/kubernetes/config kubernetes_host=https://kubernetes.default.svc
bao write auth/kubernetes/role/inventory \
  bound_service_account_names=inventory bound_service_account_namespaces=inventory \
  token_policies=inventory-app token_ttl=1h
```

## Step 3: Prove both sides of the Kubernetes login

```sh
kubectl -n inventory exec deploy/inventory-app -- sh -c \
  'curl -s -X POST -d "{\"role\":\"inventory\",\"jwt\":\"$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)\"}" http://openbao.localtest.me:8200/v1/auth/kubernetes/login'
bao write auth/kubernetes/login role=inventory jwt=$(kubectl -n inventory create token default)
```

The first login returns a token with `inventory-app`. The second is refused, because the ServiceAccount `default` is not bound to the role.

## Step 4: Create the AppRole role and store its credentials

```sh
bao write auth/approle/role/ci token_policies=ci-deploy \
  token_ttl=20m token_max_ttl=30m secret_id_ttl=24h
CI_ROLE_ID=$(bao read -field=role_id auth/approle/role/ci/role-id)
CI_SECRET_ID=$(bao write -f -field=secret_id auth/approle/role/ci/secret-id)
kubectl -n clients create secret generic ci-approle \
  --from-literal=role_id=$CI_ROLE_ID --from-literal=secret_id=$CI_SECRET_ID
bao write auth/approle/login role_id=$CI_ROLE_ID secret_id=$CI_SECRET_ID
```

The last command logs in with the stored pair and returns a token with `ci-deploy` and a duration of 20 minutes.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `bound_service_account_names=*` | The ServiceAccount `default` gets in, and the grader rejects it |
| A `secret_id` with `num_uses=1` | The grader's login uses it up; every later submit fails |
| Store a token instead of the AppRole pair | The grader logs in with `role_id` and `secret_id`, and there are none |

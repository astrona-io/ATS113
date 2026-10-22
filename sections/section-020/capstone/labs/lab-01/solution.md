# Solution: Repair Three Machine Logins

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass.

## Step 1: Connect and try each login

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
kubectl -n inventory exec deploy/inventory-app -- sh -c \
  'curl -s -X POST -d "{\"role\":\"inventory\",\"jwt\":\"$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)\"}" http://openbao.localtest.me:8200/v1/auth/kubernetes/login'
```

The Kubernetes login is refused with an error that the namespace is not authorized. Each failing login points you at the role to read next.

## Step 2: Fix the Kubernetes role

```sh
bao read auth/kubernetes/role/inventory
bao write auth/kubernetes/role/inventory \
  bound_service_account_names=inventory bound_service_account_namespaces=inventory \
  token_policies=inventory-app token_ttl=1h
```

The read shows the namespace spelled `inventry`. Writing the role again with `inventory` fixes it; run the login from Step 1 again to see a token with `inventory-app`.

## Step 3: Fix the AppRole role

```sh
bao read auth/approle/role/ci
```

`secret_id_bound_cidrs` is `10.255.0.0/16`, a range the pods are not in, so every `secret_id` is refused. Clear the limit and generate a new `secret_id`, because a `secret_id` keeps the CIDR limits it was created with:

```sh
bao write auth/approle/role/ci token_policies=ci-deploy token_ttl=20m \
  secret_id_ttl=24h secret_id_bound_cidrs=""
CI_ROLE_ID=$(bao read -field=role_id auth/approle/role/ci/role-id)
CI_SECRET_ID=$(bao write -f -field=secret_id auth/approle/role/ci/secret-id)
kubectl -n clients delete secret ci-approle
kubectl -n clients create secret generic ci-approle \
  --from-literal=role_id=$CI_ROLE_ID --from-literal=secret_id=$CI_SECRET_ID
```

In a real setup you would replace the range with the CI system's real network instead of clearing it.

## Step 4: Fix the certificate role

```sh
bao read auth/cert/certs/reporting
bao write auth/cert/certs/reporting allowed_common_names=reporting-job
kubectl -n clients exec deploy/tester -- curl -s \
  --cacert /certs/ca.crt --cert /certs/tls.crt --key /certs/tls.key \
  -X POST -d '{"name":"reporting"}' \
  https://openbao-0.openbao-internal.openbao.svc.cluster.local:8443/v1/auth/cert/login
```

The role expected `report-job`; the certificate says `reporting-job`. After the update, the login returns a token with `reporting`.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Bind the Kubernetes role to `*` | The grader rejects any binding other than `inventory` |
| Remove `allowed_common_names` | Every certificate the lab CA signs could log in; the grader rejects it |
| Fix the AppRole role but keep the old `secret_id` | The old `secret_id` still carries the bad CIDR limit |

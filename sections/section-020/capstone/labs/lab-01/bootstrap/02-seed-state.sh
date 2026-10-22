#!/usr/bin/env bash
# Creates the starting state of `ats-113-capstone-020`.
# It never creates what the task asks for.
set -uo pipefail

ROOT_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
# bao_root runs the bao CLI inside the OpenBao pod with the lab-only root token.
bao_root() { kubectl -n openbao exec -i openbao-0 -- env BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN="$ROOT_TOKEN" bao "$@"; }
# in_tester runs a command in the tester pod (namespace clients).
in_tester() { kubectl -n clients exec -i deploy/tester -- "$@"; }
# json_field reads one jq expression from JSON on stdin, using jq in the tester pod.
json_field() { kubectl -n clients exec -i deploy/tester -- jq -r "$1"; }
# login_post PATH JSON: POST a login request from the tester pod, print the response.
login_post() {
  printf '%s' "$2" | in_tester curl -s -X POST -H 'Content-Type: application/json' \
    --data-binary @- "http://openbao.localtest.me:8200/v1/$1"
}
# lookup_self TOKEN: the token's own lookup, from the tester pod.
lookup_self() {
  in_tester curl -s -H "X-Vault-Token: $1" http://openbao.localtest.me:8200/v1/auth/token/lookup-self
}
# keycloak_id_token USER: an ID token for a lab user from Keycloak's password
# grant (a lab shortcut; people log in through the browser).
keycloak_id_token() {
  in_tester curl -s -X POST \
    http://keycloak.localtest.me:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=openbao -d client_secret=openbao-client-secret \
    -d username="$1" -d password="$1-password" -d scope=openid | json_field '.id_token // empty'
}

# A KV version 2 engine at secret/ with a few example secrets, and the
# policies the module uses.
bao_root secrets list -format=json | in_tester jq -e '."secret/"' >/dev/null 2>&1 || \
  bao_root secrets enable -path=secret kv-v2
bao_root kv put secret/inventory/db username=inventory password=inventory-db-password >/dev/null
bao_root kv put secret/reports/q3 total=1200 >/dev/null
bao_root kv put secret/ci/registry username=ci password=ci-registry-password >/dev/null
bao_root kv put secret/ops/runbook text="restart the inventory app" >/dev/null
bao_root kv put secret/users/alice/note text="alice's note" >/dev/null
bao_root kv put secret/users/bob/note text="bob's note" >/dev/null

write_policy() { bao_root policy write "$1" - >/dev/null; }
write_policy inventory-read <<'HCL'
path "secret/data/inventory/*" {
  capabilities = ["read"]
}
HCL
write_policy inventory-app <<'HCL'
path "secret/data/inventory/*" {
  capabilities = ["read"]
}
HCL
write_policy reporting <<'HCL'
path "secret/data/reports/*" {
  capabilities = ["read"]
}
HCL
write_policy ci-deploy <<'HCL'
path "secret/data/ci/*" {
  capabilities = ["read"]
}
HCL
write_policy ops <<'HCL'
path "secret/data/ops/*" {
  capabilities = ["read", "list"]
}
HCL
write_policy dev <<'HCL'
path "secret/data/dev/*" {
  capabilities = ["read"]
}
HCL
write_policy ops-shared <<'HCL'
path "secret/data/ops/*" {
  capabilities = ["read"]
}
HCL
write_policy breakglass <<'HCL'
path "sys/policies/acl/*" {
  capabilities = ["read", "list"]
}
HCL

set -e
bao_root auth enable kubernetes >/dev/null 2>&1 || true
bao_root auth enable approle >/dev/null 2>&1 || true
bao_root auth enable cert >/dev/null 2>&1 || true
bao_root write auth/kubernetes/config kubernetes_host=https://kubernetes.default.svc >/dev/null
# Fault 1: the namespace is misspelled.
bao_root write auth/kubernetes/role/inventory \
  bound_service_account_names=inventory bound_service_account_namespaces=inventry \
  token_policies=inventory-app token_ttl=1h >/dev/null
# Fault 2: secret IDs only work from a network the pods are not in.
bao_root write auth/approle/role/ci token_policies=ci-deploy token_ttl=20m \
  secret_id_ttl=24h secret_id_bound_cidrs=10.255.0.0/16 >/dev/null
ROLE_ID="$(bao_root read -field=role_id auth/approle/role/ci/role-id)"
SECRET_ID="$(bao_root write -f -field=secret_id auth/approle/role/ci/secret-id)"
kubectl -n clients create secret generic ci-approle \
  --from-literal=role_id="$ROLE_ID" --from-literal=secret_id="$SECRET_ID" \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
# Fault 3: the certificate role expects the wrong common name.
CA_PEM="$(kubectl -n clients get secret client-tls -o jsonpath='{.data.ca\.crt}' | base64 -d)"
printf '%s\n' "$CA_PEM" | bao_root write auth/cert/certs/reporting \
  certificate=- allowed_common_names=report-job token_policies=reporting token_ttl=1h >/dev/null

echo "[lab] Starting state ready."

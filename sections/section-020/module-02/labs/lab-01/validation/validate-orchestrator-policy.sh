#!/usr/bin/env bash
# PASS when: Confirms the policy deploy-orchestrator allows only reading the role ID and creating a secret ID for deploy
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

pass() { echo "PASS: $1"; exit 0; }
fail() { echo "FAIL: $1"; exit 1; }

bao_root policy read deploy-orchestrator >/dev/null 2>&1 || fail "the policy deploy-orchestrator does not exist."
TOKEN="$(bao_root token create -policy=deploy-orchestrator -ttl=5m -field=token 2>/dev/null)"
[ -n "$TOKEN" ] || fail "cannot create a token with the policy deploy-orchestrator."
code_with() { in_tester curl -s -o /dev/null -w '%{http_code}' -X "$1" -H "X-Vault-Token: $TOKEN" "http://openbao.localtest.me:8200/v1/$2"; }
[ "$(code_with GET auth/approle/role/deploy/role-id)" = "200" ] || fail "the policy does not allow reading the role ID of deploy."
[ "$(code_with POST auth/approle/role/deploy/secret-id)" = "200" ] || fail "the policy does not allow creating a secret ID for deploy."
[ "$(code_with GET auth/approle/role/deploy)" = "403" ] || fail "the policy allows reading the settings of the role."
[ "$(code_with POST auth/approle/role/deploy/role-id)" = "403" ] || fail "the policy allows changing the role ID."
[ "$(code_with GET secret/data/ci/registry)" = "403" ] || fail "the policy allows reading secrets."
pass "the orchestrator can only read the role ID and create secret IDs for deploy."

#!/usr/bin/env bash
# PASS when: Confirms alice can write her own path and cannot read bob's.
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

TOKEN="$(login_post auth/userpass/login/alice '{"password":"alice-password"}' | json_field '.auth.client_token // empty')"
OWN="$(in_tester curl -s -o /dev/null -w '%{http_code}' -X POST -H "X-Vault-Token: $TOKEN" \
  -d '{"data":{"text":"checked by the grader"}}' http://openbao.localtest.me:8200/v1/secret/data/users/alice/grader)"
[ "$OWN" = "200" ] || fail "alice cannot write secret/users/alice/grader (HTTP $OWN)."
OTHER="$(in_tester curl -s -o /dev/null -w '%{http_code}' -H "X-Vault-Token: $TOKEN" http://openbao.localtest.me:8200/v1/secret/data/users/bob/note)"
[ "$OTHER" = "403" ] || fail "alice can read bob's secret (HTTP $OTHER)."
grep -q 'identity.entity' <(bao_root policy read personal) || fail "the policy personal is no longer a template."
pass "the templated policy limits alice to her own path."

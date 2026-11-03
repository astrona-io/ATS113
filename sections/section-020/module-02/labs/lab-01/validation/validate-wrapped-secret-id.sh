#!/usr/bin/env bash
# PASS when: Confirms the Secret deploy-wrapped-secret-id holds an unused 2h wrapping token for a secret ID and that secret IDs are single use
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

WRAPPED="$(kubectl -n clients get secret deploy-wrapped-secret-id -o jsonpath='{.data.token}' 2>/dev/null | base64 -d)"
[ -n "$WRAPPED" ] || fail "the Secret deploy-wrapped-secret-id has no key token in the namespace clients."
RESP="$(login_post sys/wrapping/lookup "{\"token\":\"$WRAPPED\"}")"
[ "$(printf '%s' "$RESP" | json_field '.data.creation_path // empty')" = "auth/approle/role/deploy/secret-id" ] || fail "the token is not an unused wrapping token for a deploy secret ID."
[ "$(printf '%s' "$RESP" | json_field '.data.creation_ttl')" = "7200" ] || fail "the wrapping TTL is not 2h."
ROLE_ID="$(bao_root read -field=role_id auth/approle/role/deploy/role-id)"
SECRET_ID="$(bao_root write -f -field=secret_id auth/approle/role/deploy/secret-id)"
BODY="{\"role_id\":\"$ROLE_ID\",\"secret_id\":\"$SECRET_ID\"}"
FIRST="$(login_post auth/approle/login "$BODY")"
printf '%s' "$FIRST" | in_tester jq -e '.auth.policies | index("ci-deploy")' >/dev/null || fail "a login with a new secret ID does not return ci-deploy."
[ "$(printf '%s' "$FIRST" | json_field '.auth.lease_duration')" = "600" ] || fail "the token from a login does not live 10m."
SECOND="$(login_post auth/approle/login "$BODY")"
[ -z "$(printf '%s' "$SECOND" | json_field '.auth.client_token // empty')" ] || fail "a secret ID can be used twice."
pass "the wrapped secret ID is unused, and secret IDs work once."

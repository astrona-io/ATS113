#!/usr/bin/env bash
# PASS when: Confirms the key inventory and the role inventory-reader have the requested settings
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

KEY="$(bao_root read -format=json identity/oidc/key/inventory 2>/dev/null)"
[ -n "$KEY" ] || fail "the key inventory does not exist."
[ "$(printf '%s' "$KEY" | json_field '.data.algorithm')" = "RS256" ] || fail "the algorithm is not RS256."
[ "$(printf '%s' "$KEY" | json_field '.data.rotation_period')" = "86400" ] || fail "rotation_period is not 24h."
[ "$(printf '%s' "$KEY" | json_field '.data.verification_ttl')" = "86400" ] || fail "verification_ttl is not 24h."
printf '%s' "$KEY" | in_tester jq -e '.data.allowed_client_ids | index("*")' >/dev/null || fail "allowed_client_ids does not include *."
ROLE="$(bao_root read -format=json identity/oidc/role/inventory-reader 2>/dev/null)"
[ -n "$ROLE" ] || fail "the role inventory-reader does not exist."
[ "$(printf '%s' "$ROLE" | json_field '.data.key')" = "inventory" ] || fail "the role does not use the key inventory."
[ "$(printf '%s' "$ROLE" | json_field '.data.ttl')" = "1800" ] || fail "the role ttl is not 30m."
TPL="$(printf '%s' "$ROLE" | json_field '.data.template')"
printf '%s' "$TPL" | grep -q 'identity.entity.metadata.team' || fail "the template does not use the entity metadata team."
printf '%s' "$TPL" | grep -q 'identity.entity.name' || fail "the template does not use the entity name."
pass "the key and the role are set as requested."

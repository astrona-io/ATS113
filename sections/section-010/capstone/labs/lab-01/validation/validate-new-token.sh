#!/usr/bin/env bash
# PASS when: Confirms the stored token was issued from the role and is an orphan periodic token with reporting.
set -uo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

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

TOKEN="$(kubectl -n clients get secret reporting-token -o jsonpath='{.data.token}' 2>/dev/null | base64 -d)"
LOOKUP="$(bao_root token lookup -format=json "$TOKEN" 2>/dev/null)"
[ -n "$LOOKUP" ] || fail "the token in reporting-token does not exist."
[ "$(printf '%s' "$LOOKUP" | json_field '.data.role')" = "reporting" ] || fail "the token was not created through the role reporting."
# A token that gets its period from a role shows no "period" in its lookup
# (OpenBao 2.7.1 reads the period from the role at every renewal). Accept an
# explicit 24h period, or a token of the role reporting whose role has a 24h
# token_period, with no hard limit and a TTL above the seeded one hour.
if [ "$(printf '%s' "$LOOKUP" | json_field '.data.period')" != "86400" ]; then
  ROLE_PERIOD="$(bao_root read -format=json auth/token/roles/reporting 2>/dev/null | json_field '.data.token_period')"
  TOKEN_TTL="$(printf '%s' "$LOOKUP" | json_field '.data.ttl')"
  [ "$ROLE_PERIOD" = "86400" ] \
    && [ "$(printf '%s' "$LOOKUP" | json_field '.data.explicit_max_ttl')" = "0" ] \
    && [ "${TOKEN_TTL:-0}" -gt 3600 ] 2>/dev/null \
    || fail "the token is not periodic with 24h."
fi
[ "$(printf '%s' "$LOOKUP" | json_field '.data.orphan')" = "true" ] || fail "the token is not an orphan."
printf '%s' "$LOOKUP" | json_field '.data.policies[]' | grep -qxE 'admin|root' && fail "the token has admin or root."
CODE="$(in_tester curl -s -o /dev/null -w '%{http_code}' -H "X-Vault-Token: $TOKEN" http://openbao.localtest.me:8200/v1/secret/data/reports/q3)"
[ "$CODE" = "200" ] || fail "the token cannot read secret/reports/q3."
pass "the new token comes from the fixed role."

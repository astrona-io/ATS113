#!/usr/bin/env bash
# Prepares `ats-113-capstone-040`: Helm and the bao CLI (pinned), the CoreDNS rewrite,
# OpenBao v2.7.1 initialized and unsealed, plus Keycloak 26.8.1 with the realm inventory.
#
# Environment preparation only. It never creates the objects a task asks for.
set -euo pipefail

HELM_VERSION="3.22.1"
OPENBAO_VERSION="2.7.1"
OPENBAO_CHART_VERSION="0.30.4"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Pin the tools rather than accepting whatever is on the machine.
have_helm=""
command -v helm >/dev/null 2>&1 && have_helm=$(helm version --template '{{.Version}}' 2>/dev/null | sed 's/^v//')
if [ "$have_helm" != "$HELM_VERSION" ]; then
  echo "[lab] Downloading Helm ${HELM_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz" | tar -xz -C "$WORK"
  install -m 0755 "$WORK/${OS}-${ARCH}/helm" "$BIN_DIR/helm"
fi
have_bao=""
command -v bao >/dev/null 2>&1 && have_bao=$(bao version 2>/dev/null | awk '{print $2}' | sed 's/^v//')
if [ "$have_bao" != "$OPENBAO_VERSION" ]; then
  echo "[lab] Downloading the bao CLI ${OPENBAO_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://github.com/openbao/openbao/releases/download/v${OPENBAO_VERSION}/openbao_${OPENBAO_VERSION}_${OS}_${ARCH}.tar.gz" \
    | tar -xz -C "$WORK" bao
  install -m 0755 "$WORK/bao" "$BIN_DIR/bao"
fi
helm version --short
bao version

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

# One address for the reader's machine and the cluster: <name>.localtest.me
# resolves to 127.0.0.1 on the machine (reached through a port-forward), and
# a CoreDNS block sends the same name to the Service in the cluster. The
# answer is rewritten back to the asked name: Go programs ignore DNS answers
# whose name differs from the question.
add_coredns_rewrite() {
  local host="$1" target="$2" host_re target_re corefile
  kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | grep -q "$host" && return 0
  echo "[lab] Adding the CoreDNS rewrite for ${host}..."
  host_re="$(printf '%s' "$host" | sed 's/\./\\\\./g')"
  target_re="$(printf '%s' "$target" | sed 's/\./\\\\./g')"
  corefile="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' \
    | awk -v h="$host_re" -v t="$target" -v tr="$target_re" -v hp="$host" '/^[[:space:]]*kubernetes / && !done {
        print "    rewrite stop {"
        print "        name regex " h " " t
        print "        answer name " tr " " hp
        print "    }"
        done=1
      } {print}')"
  kubectl -n kube-system create configmap coredns --from-literal=Corefile="$corefile" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n kube-system rollout restart deployment/coredns
  kubectl -n kube-system rollout status deployment/coredns --timeout=120s
}

add_coredns_rewrite openbao.localtest.me openbao.openbao.svc.cluster.local

# lab-start.yaml is also listed under bootstrap.manifests in config.yaml, so it
# may already be applied. kubectl apply is idempotent.
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
kubectl -n clients rollout restart deployment/tester >/dev/null 2>&1 || true
kubectl -n clients rollout status deployment/tester --timeout=300s

echo "[lab] Installing OpenBao (chart ${OPENBAO_CHART_VERSION})..."
helm repo add openbao https://openbao.github.io/openbao-helm >/dev/null 2>&1 || true
helm repo update openbao >/dev/null
# No --wait: a sealed OpenBao pod is never Ready, by design.
helm upgrade --install openbao openbao/openbao --version "$OPENBAO_CHART_VERSION" \
  --namespace openbao --create-namespace \
  --values "$MANIFEST_DIR/openbao-values.yaml"
for _ in $(seq 1 120); do
  [ "$(kubectl -n openbao get pod openbao-0 -o jsonpath='{.status.containerStatuses[0].started}' 2>/dev/null)" = "true" ] && break
  sleep 5
done

bao_in_pod() { kubectl -n openbao exec -i openbao-0 -- env BAO_ADDR=http://127.0.0.1:8200 bao "$@"; }

# Every ATS113 environment starts initialized and unsealed. The lab-only
# unseal key and root token are kept in the Secret openbao-init; a real
# installation never stores them in Kubernetes.
if ! kubectl -n openbao get secret openbao-init >/dev/null 2>&1; then
  echo "[lab] Initializing OpenBao with one lab-only unseal key..."
  INIT_JSON="$(bao_in_pod operator init -key-shares=1 -key-threshold=1 -format=json)"
  UNSEAL_KEY="$(printf '%s' "$INIT_JSON" | tr -d '\n ' | sed -n 's/.*"unseal_keys_b64":\["\([^"]*\)".*/\1/p')"
  ROOT_TOKEN="$(printf '%s' "$INIT_JSON" | tr -d '\n ' | sed -n 's/.*"root_token":"\([^"]*\)".*/\1/p')"
  kubectl -n openbao create secret generic openbao-init \
    --from-literal=unseal-key="$UNSEAL_KEY" --from-literal=root-token="$ROOT_TOKEN"
fi
UNSEAL_KEY="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
bao_in_pod operator unseal "$UNSEAL_KEY" >/dev/null
kubectl -n openbao wait --for=condition=Ready pod/openbao-0 --timeout=300s

add_coredns_rewrite keycloak.localtest.me keycloak.keycloak.svc.cluster.local

echo "[lab] Starting Keycloak (this can take a few minutes)..."
kubectl apply -f "$MANIFEST_DIR/keycloak.yaml"
kubectl -n keycloak rollout status deployment/keycloak --timeout=600s

kc() {
  kubectl -n keycloak exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
for _ in $(seq 1 30); do
  kc config credentials --server http://localhost:8080 --realm master \
    --user admin --password admin >/dev/null 2>&1 && break
  sleep 5
done

echo "[lab] Creating the realm inventory, the groups ops and dev, alice, bob and the client openbao..."
kc get realms/inventory >/dev/null 2>&1 || kc create realms -s realm=inventory -s enabled=true
for group in ops dev; do
  [ -n "$(kc get groups -r inventory -q search="$group" --fields id --format csv --noquotes)" ] || \
    kc create groups -r inventory -s name="$group"
done
create_user() {
  local user="$1" first="$2" group="$3" user_id group_id
  if [ -z "$(kc get users -r inventory -q username="$user" -q exact=true --fields id --format csv --noquotes)" ]; then
    kc create users -r inventory -s username="$user" -s enabled=true \
      -s email="$user@example.com" -s emailVerified=true -s firstName="$first" -s lastName=Example
    kc set-password -r inventory --username "$user" --new-password "$user-password"
  fi
  user_id="$(kc get users -r inventory -q username="$user" -q exact=true --fields id --format csv --noquotes)"
  group_id="$(kc get groups -r inventory -q search="$group" --fields id --format csv --noquotes | head -1)"
  kc update "users/$user_id/groups/$group_id" -r inventory -s realm=inventory \
    -s userId="$user_id" -s groupId="$group_id" -n
}
create_user alice Alice ops
create_user bob Bob dev

# Confidential client for OpenBao. Direct access grants (the password grant)
# are on only so graders can get an ID token without a browser: lab-only.
if [ -z "$(kc get clients -r inventory -q clientId=openbao --fields id --format csv --noquotes)" ]; then
  kc create clients -r inventory -s clientId=openbao -s enabled=true \
    -s publicClient=false -s secret=openbao-client-secret \
    -s standardFlowEnabled=true -s directAccessGrantsEnabled=true \
    -s 'redirectUris=["http://localhost:8250/oidc/callback","http://openbao.localtest.me:8200/ui/vault/auth/oidc/oidc/callback"]'
  client_id="$(kc get clients -r inventory -q clientId=openbao --fields id --format csv --noquotes)"
  # Put the user's groups, without the leading slash, into the claim `groups`.
  kc create "clients/$client_id/protocol-mappers/models" -r inventory \
    -s name=groups -s protocol=openid-connect -s protocolMapper=oidc-group-membership-mapper \
    -s 'config."claim.name"=groups' -s 'config."full.path"=false' \
    -s 'config."id.token.claim"=true' -s 'config."access.token.claim"=true' \
    -s 'config."userinfo.token.claim"=true'
fi

echo "[lab] OpenBao is initialized and unsealed."

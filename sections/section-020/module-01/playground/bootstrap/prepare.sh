#!/usr/bin/env bash
# Prepares `ats-113-playground-020-01`: Helm and the bao CLI (pinned), the CoreDNS rewrite,
# OpenBao v2.7.1 initialized and unsealed, plus the lab CA and TLS certificates, the inventory application.
#
# Environment preparation only. It never creates the objects a task asks for.
set -euo pipefail
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
  echo "[playground] Downloading Helm ${HELM_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz" | tar -xz -C "$WORK"
  install -m 0755 "$WORK/${OS}-${ARCH}/helm" "$BIN_DIR/helm"
fi
have_bao=""
command -v bao >/dev/null 2>&1 && have_bao=$(bao version 2>/dev/null | awk '{print $2}' | sed 's/^v//')
if [ "$have_bao" != "$OPENBAO_VERSION" ]; then
  echo "[playground] Downloading the bao CLI ${OPENBAO_VERSION} (${OS}/${ARCH})..."
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
  echo "[playground] Adding the CoreDNS rewrite for ${host}..."
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

# Lab-only certificates: one CA (lab-ca) signs the server certificate of the
# TLS listener and the client certificate of the reporting job (CN
# reporting-job). openssl runs on the machine; the keys go into two Secrets.
if ! kubectl -n openbao get secret openbao-tls >/dev/null 2>&1; then
  echo "[playground] Creating the lab CA, the server certificate and the client certificate..."
  kubectl create namespace openbao --dry-run=client -o yaml | kubectl apply -f -
  kubectl create namespace clients --dry-run=client -o yaml | kubectl apply -f -
  (
    cd "$WORK"
    openssl req -x509 -newkey rsa:2048 -nodes -days 30 -subj "/CN=lab-ca" \
      -keyout ca.key -out ca.crt 2>/dev/null
    openssl req -newkey rsa:2048 -nodes -subj "/CN=openbao" \
      -keyout server.key -out server.csr 2>/dev/null
    printf 'subjectAltName=DNS:openbao-0.openbao-internal.openbao.svc.cluster.local,DNS:openbao-0.openbao-internal,DNS:localhost,IP:127.0.0.1\nextendedKeyUsage=serverAuth\n' > server.ext
    openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
      -days 30 -extfile server.ext -out server.crt 2>/dev/null
    openssl req -newkey rsa:2048 -nodes -subj "/CN=reporting-job" \
      -keyout client.key -out client.csr 2>/dev/null
    printf 'extendedKeyUsage=clientAuth\n' > client.ext
    openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
      -days 30 -extfile client.ext -out client.crt 2>/dev/null
  )
  kubectl -n openbao create secret generic openbao-tls \
    --from-file=tls.crt="$WORK/server.crt" --from-file=tls.key="$WORK/server.key" \
    --from-file=ca.crt="$WORK/ca.crt"
  kubectl -n clients create secret generic client-tls \
    --from-file=tls.crt="$WORK/client.crt" --from-file=tls.key="$WORK/client.key" \
    --from-file=ca.crt="$WORK/ca.crt"
fi

add_coredns_rewrite openbao.localtest.me openbao.openbao.svc.cluster.local

# lab-start.yaml is also listed under bootstrap.manifests in config.yaml, so it
# may already be applied. kubectl apply is idempotent.
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
kubectl -n clients rollout restart deployment/tester >/dev/null 2>&1 || true
kubectl -n clients rollout status deployment/tester --timeout=300s

echo "[playground] Installing OpenBao (chart ${OPENBAO_CHART_VERSION})..."
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
  echo "[playground] Initializing OpenBao with one lab-only unseal key..."
  INIT_JSON="$(bao_in_pod operator init -key-shares=1 -key-threshold=1 -format=json)"
  UNSEAL_KEY="$(printf '%s' "$INIT_JSON" | tr -d '\n ' | sed -n 's/.*"unseal_keys_b64":\["\([^"]*\)".*/\1/p')"
  ROOT_TOKEN="$(printf '%s' "$INIT_JSON" | tr -d '\n ' | sed -n 's/.*"root_token":"\([^"]*\)".*/\1/p')"
  kubectl -n openbao create secret generic openbao-init \
    --from-literal=unseal-key="$UNSEAL_KEY" --from-literal=root-token="$ROOT_TOKEN"
fi
UNSEAL_KEY="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
bao_in_pod operator unseal "$UNSEAL_KEY" >/dev/null
kubectl -n openbao wait --for=condition=Ready pod/openbao-0 --timeout=300s

kubectl -n inventory rollout status deployment/inventory-app --timeout=300s

echo "[playground] OpenBao is initialized and unsealed."

# --- the playground's starting content ---

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

echo "[playground] Ready."
echo "[playground] Start the port-forward in a second terminal before you use bao:"
echo "  kubectl -n openbao port-forward svc/openbao 8200:8200"
echo "  export BAO_ADDR=http://openbao.localtest.me:8200"
echo "  export BAO_TOKEN=\$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"

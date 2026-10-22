#!/usr/bin/env bash
# Runs before the reference solution: waits until OpenBao answers unsealed
# from the tester pod.
set -eu
for _ in $(seq 1 90); do
  sealed="$(kubectl -n clients exec deploy/tester -- curl -s http://openbao.localtest.me:8200/v1/sys/seal-status 2>/dev/null | kubectl -n clients exec -i deploy/tester -- jq -r '.sealed' 2>/dev/null || true)"
  [ "$sealed" = "false" ] && exit 0
  sleep 2
done
echo "OpenBao did not answer unsealed in time." >&2
exit 1

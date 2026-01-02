#!/usr/bin/env bash

NS=audit-zone
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl apply -f "$ROOT/01-create-namespace.yaml" >/dev/null
fail_apply () {
  local file="$1"
  set +e
  kubectl apply -f "$file" 2>err.txt 1>/dev/null
  rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then
    echo "ERROR: ${file} applied, expected rejection"
    exit 1
  fi
  cat err.txt
}
fail_apply "$ROOT/insecure-manifests/01-privileged-pod.yaml"
fail_apply "$ROOT/insecure-manifests/02-hostpath-pod.yaml"
fail_apply "$ROOT/insecure-manifests/03-root-user-pod.yaml"
kubectl apply -f "$ROOT/secure-manifests/01-secure.yaml"
kubectl apply -f "$ROOT/secure-manifests/02-secure.yaml"
kubectl apply -f "$ROOT/secure-manifests/03-secure.yaml"
kubectl -n "$NS" wait --for=condition=Ready pod/pod-secure-no-privileged --timeout=60s
kubectl -n "$NS" wait --for=condition=Ready pod/pod-secure-no-hostpath --timeout=60s
kubectl -n "$NS" wait --for=condition=Ready pod/pod-secure-nonroot --timeout=60s

#!/usr/bin/env bash
set -euo pipefail

# Task4: привязка групп пользователей к ролям (RoleBinding / ClusterRoleBinding)
# Группы (пример):
# - sales-viewers, sales-devs
# - tenant-viewers, tenant-devs
# - finance-viewers, finance-devs
# - data-viewers, data-devs
# - platform-ops
# - security-auditors

k() {
  if [[ -n "${KUBECTL:-}" ]]; then
    ${KUBECTL} "$@"
    return
  fi
  if command -v kubectl >/dev/null 2>&1; then
    if kubectl cluster-info >/dev/null 2>&1; then
      kubectl "$@"
      return
    fi
  fi
  if command -v minikube >/dev/null 2>&1; then
    minikube kubectl -- "$@"
    return
  fi
  if command -v minikube.exe >/dev/null 2>&1; then
    minikube.exe kubectl -- "$@"
    return
  fi
  echo "ERROR: kubectl не доступен (и minikube kubectl тоже). Установи kubectl/minikube или выставь KUBECTL." >&2
  exit 1
}

echo "==> Creating RoleBindings in domain namespaces"

k apply -f - <<'YAML'
# SALES
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sales-viewers-rb
  namespace: sales
subjects:
  - kind: Group
    name: sales-viewers
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ns-viewer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sales-devs-rb
  namespace: sales
subjects:
  - kind: Group
    name: sales-devs
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ns-deployer
---
# TENANT
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tenant-viewers-rb
  namespace: tenant
subjects:
  - kind: Group
    name: tenant-viewers
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ns-viewer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tenant-devs-rb
  namespace: tenant
subjects:
  - kind: Group
    name: tenant-devs
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ns-deployer
---
# FINANCE
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: finance-viewers-rb
  namespace: finance
subjects:
  - kind: Group
    name: finance-viewers
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ns-viewer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: finance-devs-rb
  namespace: finance
subjects:
  - kind: Group
    name: finance-devs
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ns-deployer
---
# DATA
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: data-viewers-rb
  namespace: data
subjects:
  - kind: Group
    name: data-viewers
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ns-viewer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: data-devs-rb
  namespace: data
subjects:
  - kind: Group
    name: data-devs
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ns-deployer
YAML

echo "==> Creating ClusterRoleBindings for privileged/global groups"
k apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: platform-ops-crb
subjects:
  - kind: Group
    name: platform-ops
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-configurator
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: security-auditors-crb
subjects:
  - kind: Group
    name: security-auditors
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: secrets-auditor
YAML

echo "==> Done: bindings created."

#!/usr/bin/env bash
set -euo pipefail

# Task4: создание namespaces и RBAC ролей (ClusterRole)
# Роли:
# - ns-viewer (ClusterRole, биндим RoleBinding-ом в нужные namespaces)
# - ns-deployer (ClusterRole, биндим RoleBinding-ом в нужные namespaces)
# - cluster-configurator (ClusterRoleBinding для platform-ops)
# - secrets-auditor (ClusterRoleBinding для security-auditors)

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

echo "==> Creating namespaces"
k apply -f - <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: sales
---
apiVersion: v1
kind: Namespace
metadata:
  name: tenant
---
apiVersion: v1
kind: Namespace
metadata:
  name: finance
---
apiVersion: v1
kind: Namespace
metadata:
  name: data
---
apiVersion: v1
kind: Namespace
metadata:
  name: platform
YAML

echo "==> Creating ClusterRoles"
k apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ns-viewer
rules:
  # Core objects (без secrets)
  - apiGroups: [""]
    resources: ["pods","pods/log","services","endpoints","configmaps","events","serviceaccounts"]
    verbs: ["get","list","watch"]
  # Workloads
  - apiGroups: ["apps"]
    resources: ["deployments","replicasets","statefulsets","daemonsets"]
    verbs: ["get","list","watch"]
  - apiGroups: ["batch"]
    resources: ["jobs","cronjobs"]
    verbs: ["get","list","watch"]
  # Networking (read-only)
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses","networkpolicies"]
    verbs: ["get","list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ns-deployer
rules:
  # Управление workloads в namespace (без RBAC и без secrets)
  - apiGroups: ["apps"]
    resources: ["deployments","replicasets","statefulsets","daemonsets"]
    verbs: ["get","list","watch","create","update","patch","delete"]
  - apiGroups: ["batch"]
    resources: ["jobs","cronjobs"]
    verbs: ["get","list","watch","create","update","patch","delete"]
  - apiGroups: [""]
    resources: ["pods","pods/log","services","endpoints","configmaps","events"]
    verbs: ["get","list","watch","create","update","patch","delete"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses","networkpolicies"]
    verbs: ["get","list","watch","create","update","patch","delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-configurator
rules:
  # Namespaces (cluster-scoped)
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get","list","watch","create","update","patch","delete"]
  # RBAC управление в namespaces (и при необходимости clusterrole read)
  - apiGroups: ["rbac.authorization.k8s.io"]
    resources: ["roles","rolebindings"]
    verbs: ["get","list","watch","create","update","patch","delete"]
  - apiGroups: ["rbac.authorization.k8s.io"]
    resources: ["clusterroles","clusterrolebindings"]
    verbs: ["get","list","watch"]   # без изменения (чтобы не быть cluster-admin)
  # Настройка сетевой изоляции и ingress
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies","ingresses","ingressclasses"]
    verbs: ["get","list","watch","create","update","patch","delete"]
  # Базовые лимиты/квоты
  - apiGroups: [""]
    resources: ["resourcequotas","limitranges","serviceaccounts","configmaps","services"]
    verbs: ["get","list","watch","create","update","patch","delete"]
  # Узлы — только чтение (для диагностики)
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get","list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secrets-auditor
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get","list","watch"]
  # Контекст для расследований
  - apiGroups: [""]
    resources: ["pods","pods/log","events","configmaps","namespaces"]
    verbs: ["get","list","watch"]
YAML

echo "==> Done: namespaces + ClusterRoles created."

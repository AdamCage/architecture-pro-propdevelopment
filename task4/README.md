# Task4 — RBAC для Minikube

Артефакты:
- `roles.md` — таблица ролей/прав/групп.
- `create-users.sh` — создание пользователей через Kubernetes CSR API (без доступа к ca.key).
- `create-roles.sh` — создание namespaces и ClusterRole.
- `bind-users.sh` — привязка групп к ролям (RoleBinding / ClusterRoleBinding).

## Запуск (Linux/macOS/WSL)

1) Поднять Minikube и убедись, что kubectl видит кластер:

```bash
minikube start
kubectl cluster-info
```

2) Прогнать скрипты:

```bash
bash create-roles.sh
bash bind-users.sh
bash create-users.sh
```

3) Проверки:

```bash
kubectl --context alice@sales auth can-i get pods -n sales
kubectl --context alice@sales auth can-i get secrets -n sales        # ожидается: no

kubectl --context bob@platform auth can-i create namespace           # ожидается: yes
kubectl --context bob@platform auth can-i delete secrets -n sales     # ожидается: no

kubectl --context carol@default auth can-i get secrets -n sales       # ожидается: yes
```

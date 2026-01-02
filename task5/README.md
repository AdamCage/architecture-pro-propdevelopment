# Task5 — NetworkPolicy

Файл `non-admin-api-allow.yaml` содержит набор NetworkPolicy, которые:

- включают **default deny** по ingress для всех Pod в namespace;
- разрешают трафик **в обе стороны** только для пар:
  - `front-end` ↔ `back-end-api`
  - `admin-front-end` ↔ `admin-back-end-api`
- запрещают любой иной east-west трафик между Pod внутри namespace (за счёт default deny + точечных allow).

## Развёртывание тестовых Pod/Service (пример)

```bash
kubectl create ns task5
kubectl config set-context --current --namespace=task5

kubectl run front-end-app --image=nginx --labels role=front-end --expose --port 80
kubectl run back-end-api-app --image=nginx --labels role=back-end-api --expose --port 80

kubectl run admin-front-end-app --image=nginx --labels role=admin-front-end --expose --port 80
kubectl run admin-back-end-api-app --image=nginx --labels role=admin-back-end-api --expose --port 80

kubectl apply -f non-admin-api-allow.yaml
```

## Проверки

> Важно: тестовый Pod тоже должен иметь label `role=...`, иначе его запросы будут блокироваться по ingress.

```bash
kubectl run test-fe --rm -it --restart=Never --image=alpine --labels role=front-end -- sh
/ # apk add --no-cache wget
/ # wget -qO- --timeout=2 http://back-end-api-app            # OK
/ # wget -qO- --timeout=2 http://admin-back-end-api-app      # BLOCK

kubectl run test-admin-fe --rm -it --restart=Never --image=alpine --labels role=admin-front-end -- sh
/ # apk add --no-cache wget
/ # wget -qO- --timeout=2 http://admin-back-end-api-app      # OK
/ # wget -qO- --timeout=2 http://back-end-api-app            # BLOCK
```

## Примечание по Minikube

NetworkPolicy работают только при наличии CNI, который их реализует (например, Calico).
Для Minikube можно использовать:

```bash
minikube delete
minikube start --cni=calico
```

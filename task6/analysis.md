# Отчёт по результатам анализа Kubernetes Audit Log

## Подозрительные события

1. Доступ к секретам:
   - Кто: system:apiserver
   - Где: namespace=не указан, ресурс=secrets, имя=—
   - Почему подозрительно: Сервис-аккаунт читает secrets (верб=list). Может указывать на разведку прав.

2. Привилегированные поды:
   - Кто: system:serviceaccount:kube-system:daemon-set-controller
   - Комментарий: Создан pod с privileged=true — потенциальная эскалация до узла.

3. Использование kubectl exec в чужом поде:
   - Не обнаружено.

4. Создание RoleBinding с правами cluster-admin:
   - Кто: system:apiserver
   - К чему привело: Эскалация до cluster-admin через RoleBinding/ClusterRoleBinding.

5. Удаление audit-policy.yaml:
   - Не обнаружено.

## Вывод

- Найдено событий: 42. Из них: secrets-access=14, privileged-pod=2, cross-namespace-exec=0, cluster-admin-binding=4, audit-policy-tamper=0.
- Компрометацией кластера можно считать: создание привилегированного pod, exec в системном namespace, выдачу cluster-admin через RoleBinding, а также попытку/факт отключения аудита.
- Недочёты RBAC-политики: отсутствие ограничений на создание привилегированных pod'ов; возможность читать secrets из чужих namespace; возможность связывать ServiceAccount с cluster-admin.

### Приложение: сводка по актёрам (top):
- system:serviceaccount:kube-system:metrics-server: 12
- system:node:minikube: 6
- minikube-user: 6
- system:apiserver: 5
- system:kube-controller-manager: 4
- kubernetes-admin: 2
- system:serviceaccount:kube-system:certificate-controller: 2
- system:serviceaccount:secure-ops:monitoring: 2
- kubernetes-super-admin: 1
- minikube: 1
# Task4 — RBAC роли и группы пользователей (PropDevelopment)

Цель: ограничить доступ к Kubernetes по ролям и по доменам компании (Sales / Tenant / Finance / Data) и выделить привилегированную группу для ИБ.

## Роли и полномочия

| Роль (RBAC) | Права роли | Группы пользователей (примеры) |
| --- | --- | --- |
| `ns-viewer` | Только чтение (`get/list/watch`) ресурсов приложений в пределах namespace. **Секреты недоступны.** | `sales-viewers`, `tenant-viewers`, `finance-viewers`, `data-viewers` (менеджеры, бизнес/BI-аналитики, операционная команда) |
| `ns-deployer` | Управление приложениями в пределах namespace (deployments/statefulsets/daemonsets/jobs/services/ingress/configmaps). **Секреты и RBAC недоступны.** | `sales-devs`, `tenant-devs`, `finance-devs`, `data-devs` (продуктовые команды доменов) |
| `cluster-configurator` | Настройка кластера: namespaces (`*`), а также управление `roles/rolebindings` и `networkpolicies/ingress` по всем namespaces. Узлы (`nodes`) — только чтение. | `platform-ops` (DevOps/платформенная команда) |
| `secrets-auditor` | Привилегированное действие: чтение `secrets` (`get/list/watch`) по всем namespaces + чтение контекста (pods/events/configmaps). | `security-auditors` (специалист/команда ИБ) |

## Организация по namespaces (пример)

- `sales` — сервисы для покупателей (витрина, client-*, интеграции)
- `tenant` — сервисы для собственников (tenant-*, CRM по собственникам)
- `finance` — финансовые сервисы
- `data` — DWH/BI/отчётность
- `platform` — инфраструктурные компоненты (ingress/monitoring/cicd и т.п.)

## Пользователи (минимум два)

В демо создаются пользователи (x509 client cert auth):

- `alice` — группа `sales-viewers`
- `bob` — группа `platform-ops`
- `carol` — группа `security-auditors`

Пользователей можно добавлять по аналогии (см. `03-create-users.sh`).

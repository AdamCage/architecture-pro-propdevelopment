# Task 7 
Namespace audit-zone настроен с политикой PodSecurity уровня restricted. Небезопасные манифесты отклоняются, безопасные успешно создаются. 

## 1 Очистим кластер от предыдущих запусков
./restore.sh


# 2. Создадим namespace audit-zone с уровнем PodSecurity restricted
kubectl apply -f 01-create-namespace.yaml

# 3. Установим OPA Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml

ждем окончания установки
kubectl get pods -n gatekeeper-system 
Должны быть все Running 

# 4. Применим OPA-шаблоны и ограничения
kubectl apply -f gatekeeper/constraint-templates/
kubectl apply -f gatekeeper/constraints/

# 5. Проверим работу Gatekeeper
bash verify/verify-admission.sh
bash verify/validate-security.sh   









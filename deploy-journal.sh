#!/bin/bash

export DOCKER_HOST=unix:///var/run/docker.sock

echo "Сборка Docker-образа журнальной системы"
docker build -t journal-api:v1 .

echo "Загрузка образа в Minikube"
minikube image load journal-api:v1

echo "Применение Kubernetes-манифестов"

echo "Создание пространства имен для журнальной системы"
kubectl apply -f kubernetes/namespace.yaml

echo "Создание ConfigMap с настройками"
kubectl apply -f kubernetes/configmap.yaml

echo "Создание тестового пода"
kubectl apply -f kubernetes/test-pod.yaml

echo "Ожидание готовности тестового пода..."
kubectl wait --namespace=journal-system --for=condition=Ready pod/journal-test --timeout=60s

echo "Создание основного развертывания"
kubectl apply -f kubernetes/deployment.yaml

echo "Создание сервиса для доступа к API"
kubectl apply -f kubernetes/service.yaml

echo "Создание хранилища для архивов журналов"
kubectl apply -f kubernetes/storage.yaml

echo "Создание DaemonSet для сбора журналов"
kubectl apply -f kubernetes/daemonset.yaml

echo "Создание CronJob для периодического архивирования"
kubectl apply -f kubernetes/cronjob.yaml

echo "Ожидание готовности приложения..."
kubectl wait --namespace=journal-system --for=condition=Available deployment/journal-api --timeout=120s

echo ""
echo "Все компоненты системы журналирования успешно развернуты!"
echo ""
echo "Для проверки работы выполните:"
echo "kubectl port-forward -n journal-system service/journal-api-service 8080:80"
echo "Затем откройте в браузере http://localhost:8080 или выполните команды:"
echo "curl http://localhost:8080/status"
echo "curl -X POST http://localhost:8080/log -H 'Content-Type: application/json' -d '{\"message\":\"тестовая запись\"}'"
echo "curl http://localhost:8080/logs"

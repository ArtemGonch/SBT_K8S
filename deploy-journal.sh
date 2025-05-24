#!/bin/bash

export DOCKER_HOST=unix:///var/run/docker.sock

echo "Устанавливаем Istio с профилем demo..."
istioctl install --set profile=demo -y

echo "Сборка Docker-образа журнальной системы"
docker build -t journal-api:v1 .

echo "Загрузка образа в Minikube"
minikube image load journal-api:v1

echo "Применение Kubernetes-манифестов"

echo "Создание пространства имен для журнальной системы"
kubectl apply -f kubernetes/namespace.yaml

echo "Включаем автоматический injection Istio для пространства имен journal-system..."
kubectl label namespace journal-system istio-injection=enabled --overwrite

echo "Установка базового Prometheus..."
kubectl apply -f kubernetes/prometheus.yaml

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

echo "Применение конфигурации Istio"
kubectl apply -f kubernetes/istio-gateway.yaml
kubectl apply -f kubernetes/istio-virtualservice.yaml
kubectl apply -f kubernetes/istio-destinationrule.yaml

echo "Ожидание готовности приложения..."
kubectl wait --namespace=journal-system --for=condition=Available deployment/journal-api --timeout=120s

echo "Ожидание готовности Prometheus..."
kubectl wait --namespace=journal-system --for=condition=Available deployment/prometheus --timeout=60s

echo ""
echo "Все компоненты системы журналирования, Istio и Prometheus успешно развернуты!"
echo ""
echo "Для проверки работы журнальной системы выполните:"
echo "kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80"
echo "Затем откройте в браузере http://localhost:8080 или выполните команды:"
echo "curl http://localhost:8080/status"
echo "curl -X POST http://localhost:8080/log -H 'Content-Type: application/json' -d '{\"message\":\"тестовая запись\"}'"
echo "curl http://localhost:8080/logs"
echo ""
echo "Для проверки метрик приложения:"
echo "curl http://localhost:8080/metrics"
echo ""
echo "Для доступа к Prometheus выполните:"
echo "kubectl port-forward -n journal-system svc/prometheus 9090:9090"
echo "Затем откройте в браузере http://localhost:9090"
echo ""
echo "Проверьте метрики приложения в Prometheus, выполнив запрос:"
echo "journal_log_requests_total"
echo ""
echo "Также доступны метрики Istio, например:"
echo "istio_requests_total"

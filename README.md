# SBT_K8S

"Для проверки работы выполните: ```sh deploy-journal.sh```"

```kubectl port-forward -n journal-system service/journal-api-service 8080:80```

```Затем откройте в браузере http://localhost:8080 или выполните команды:```

```curl http://localhost:8080/status```

```curl -X POST http://localhost:8080/log -H 'Content-Type: application/json' -d '{\"message\":\"тестовая запись\"}'```

```curl http://localhost:8080/logs```
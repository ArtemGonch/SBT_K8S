import os
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import PlainTextResponse
from loguru import logger
from pydantic import BaseModel

app = FastAPI(
    title="JournalAPI",
    description="Система для ведения и хранения журналов",
    version="1.0.0"
)

APP_GREETING = os.getenv("APP_GREETING", "Welcome to the custom app")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
JOURNAL_PATH = Path("/srv/journals/app.log")

logger.remove()
logger.add(JOURNAL_PATH, level=LOG_LEVEL)
logger.add(lambda msg: print(msg, end=""), level=LOG_LEVEL)


class JournalEntry(BaseModel):
    message: str


@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = datetime.now()
    response = await call_next(request)
    process_time = (datetime.now() - start_time).total_seconds() * 1000
    logger.debug(f"{request.method} {request.url.path} - {process_time:.2f}ms")
    return response


@app.get("/", response_class=PlainTextResponse)
async def homepage():
    logger.info("Запрос к домашней странице")
    return APP_GREETING


@app.get("/status")
async def system_status() -> Dict[str, str]:
    logger.info("Проверка состояния системы")
    return {"status": "ok"}


@app.post("/log")
async def write_log(entry: JournalEntry) -> Dict[str, Any]:
    timestamp = datetime.now().isoformat()

    try:
        with open(JOURNAL_PATH, "a") as log_file:
            log_file.write(f"{timestamp} - {entry.message}\n")

        logger.info(f"Добавлена запись в журнал: {entry.message}")

        return {
            "status": "success",
            "timestamp": timestamp,
            "message": "Запись сохранена в журнале"
        }
    except Exception as e:
        logger.error(f"Ошибка при записи в журнал: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Не удалось записать в журнал: {str(e)}")


@app.get("/logs", response_class=PlainTextResponse)
async def get_logs() -> str:
    logger.info("Запрос содержимого журнала")

    try:
        if not JOURNAL_PATH.exists():
            logger.warning(f"Файл журнала не найден: {JOURNAL_PATH}")
            return "Журнал пуст"

        content = JOURNAL_PATH.read_text()
        return content
    except Exception as e:
        logger.error(f"Ошибка при чтении журнала: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Ошибка доступа к журналу: {str(e)}")


@app.on_event("startup")
async def startup_event():
    logger.info("Приложение для ведения журналов запущено")
    logger.info(f"Уровень журналирования: {LOG_LEVEL}")
    logger.info(f"Путь к файлу журнала: {JOURNAL_PATH}")

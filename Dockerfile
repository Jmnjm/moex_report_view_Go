# Черновик, ещё не тестировал запуск целиком в контейнере — доделаю на следующем шаге.

FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# сканируем отчёты и поднимаем сервер
CMD ["sh", "-c", "python scan_reports.py && uvicorn main:app --host 0.0.0.0 --port 8000"]

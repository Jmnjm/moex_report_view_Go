# Многоступенчатая сборка: на первом этапе компилируем Go-бинарник,
# на втором - кладём его в лёгкий образ без всего инструментария
# сборки. В Python-версии такого разделения не было - там весь
# интерпретатор нужен и на этапе сборки, и на этапе запуска, а
# скомпилированный Go-бинарник для работы интерпретатор уже не нужен.

FROM golang:1.22 AS builder
WORKDIR /app
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o report-viewer .

# Второй этап: минимальный образ, только бинарник + xsltproc,
# который нужен transform.go для трансформации на этапе выполнения
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends xsltproc ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/report-viewer .
CMD ["./report-viewer"]

# Мониторинг с Prometheus и Grafana

## Быстрый старт

### 1. Подготовка директорий

```bash
chown -R 65534:65534 data
```

### 2. Запуск сервисов

```bash
docker-compose up -d
```

### 3. Проверка работы

- **Prometheus**: http://localhost:9090
- **Node Exporter**: http://localhost:9100/metrics
- **Grafana**: http://localhost:3000
  - Логин: `admin`
  - Пароль: `admin`

### 4. Настройка Grafana

1. Добавьте источник данных Prometheus: `http://prometheus:9090`
2. Импортируйте дашборд с ID: **1860** (Node Exporter Full)

## Остановка

```bash
docker-compose down
```

## Просмотр логов

```bash
docker-compose logs -f
```


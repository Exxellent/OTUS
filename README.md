# Домашнее задание: Docker

## Описание задач

В данной лабораторной работе были поставлены следующие задачи:

1. Установить Docker на хост машину
2. Установить Docker Compose (как плагин или отдельное приложение)
3. Создать кастомный образ nginx на базе alpine с кастомной страницей
4. Определить разницу между контейнером и образом
5. Ответить на вопрос: Можно ли в контейнере собрать ядро?

---

## 1. Установка Docker

### Установка Docker Engine на Ubuntu

```bash
# Обновление пакетов
sudo apt update
sudo apt install ca-certificates curl

# Создание директории для ключей
sudo install -m 0755 -d /etc/apt/keyrings

# Добавление официального GPG ключа Docker
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Добавление репозитория Docker
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Установка Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Проверка установки

```bash
sudo docker --version
sudo docker run hello-world
```

---

## 2. Создание кастомного образа Nginx на базе Alpine

### Структура проекта

```
OTUS/
├── Dockerfile              # Описание образа
├── nginx.conf             # Конфигурация nginx
├── index.html             # Кастомная HTML страница
├── docker-compose.yml     # Конфигурация для docker-compose
└── README.md              # Документация
```

### Dockerfile

```dockerfile
FROM alpine:latest

RUN apk add --no-cache nginx

RUN mkdir -p /var/www/html /var/log/nginx /run/nginx

COPY nginx.conf /etc/nginx/nginx.conf

COPY index.html /var/www/html/index.html

RUN chown -R nginx:nginx /var/www/html /var/log/nginx /run/nginx && \
    nginx -t

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
```

### Конфигурация nginx (nginx.conf)

Nginx настроен на прослушивание порта 8080 и отдачу кастомной страницы из `/var/www/html/index.html`.

### Сборка образа

```bash
docker build -t exxellent/otus .
```

### Запуск контейнера

**Вариант 1: Через docker run**
```bash
docker run -d -p 8080:8080 --name otus exxellent/otus
```

**Вариант 2: Через docker-compose**
```bash
docker compose up -d
```

### Проверка работы

Откройте в браузере: `http://localhost:8080`

Вы должны увидеть кастомную страницу с текстом "HELLO OTUS".

### Остановка контейнера

```bash
# Если запускали через docker run
docker stop otus
docker rm otus

# Если запускали через docker-compose
docker compose down
```

---

## 3. Разница между контейнером и образом

### Образ (Image)

**Образ** — это неизменяемый шаблон, используемый для создания контейнеров. Образ содержит:
- Файловую систему (layers)
- Метаданные (конфигурация, переменные окружения)
- Инструкции для запуска приложения

### Контейнер (Container)

**Контейнер** — это запущенный экземпляр образа. Контейнер:
- Создается из образа
- Имеет свой собственный изолированный процесс
- Имеет изменяемый слой (writable layer) поверх образа
- Изолирован от других контейнеров и хоста

---

## 5. Можно ли в контейнере собрать ядро?

**Технически возможно, но практически нецелесообразно и имеет серьезные ограничения.**

### Подробное объяснение

#### Технические возможности

1. **Доступ к инструментам компиляции:**
   - В контейнере можно установить компиляторы (gcc, make, build-essential)
   - Можно установить необходимые библиотеки и заголовочные файлы
   - Можно скачать исходный код ядра Linux

2. **Процесс сборки:**
   ```bash
   # Технически можно выполнить
   docker run -it ubuntu:latest bash
   apt update && apt install -y build-essential linux-source
   # ... компиляция ядра
   ```

#### Ограничения и проблемы

1. **Изоляция контейнера:**
   - Контейнер использует ядро хоста, а не свое собственное
   - Собранное ядро в контейнере не может быть загружено из контейнера
   - Для загрузки ядра нужен доступ к загрузчику (GRUB), который недоступен из контейнера

2. **Права доступа:**
   - Сборка ядра требует привилегированного доступа
   - Нужны специальные флаги (`--privileged`) для доступа к устройствам
   - Это нарушает принципы безопасности контейнеризации

3. **Практическая бесполезность:**
   - Собранное ядро не может быть использовано контейнером
   - Ядро должно быть загружено на уровне хоста
   - Контейнер всегда использует ядро хостовой системы

4. **Ресурсы:**
   - Сборка ядра требует значительных ресурсов (CPU, память, диск)
   - Контейнеры предназначены для легковесных приложений
   - Это противоречит философии контейнеризации


---

## Заключение

В ходе выполнения домашнего задания были изучены основы работы с Docker:
- Установка Docker Engine и Docker Compose
- Создание кастомного образа на базе Alpine
- Понимание разницы между образом и контейнером
- Собран образ и запушен в репо
```
docker pull exxellent/otus:latest
```
https://hub.docker.com/r/exxellent/otus/tags


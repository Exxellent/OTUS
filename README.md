# Домашнее задание: Systemd - создание unit-файлов

## Описание задач

В данной лабораторной работе были поставлены следующие задачи:

1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/default).
2. Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта (https://gist.github.com/cea2k/1318020).
3. Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно.




## Решение

### 1. Мониторинг логов (log_monitor.yml)

**Что делает playbook:**
- Копирует скрипт мониторинга логов в `/usr/local/bin/log-monitor.sh`
- Создает конфигурационный файл `/etc/default/log-monitor` с настройками
- Создает systemd service файл `/etc/systemd/system/log-monitor.service`
- Создает systemd timer файл `/etc/systemd/system/log-monitor.timer` для запуска каждые 30 секунд
- Перезагружает systemd и запускает timer

**Результат:** Сервис автоматически мониторит системные логи каждые 30 секунд на предмет наличия слова "ERROR" и выводит найденные строки в systemd journal.

### 2. Spawn-fcgi (spawn-fcgi.yml)

**Что делает playbook:**
- Устанавливает пакеты: spawn-fcgi, php, php-cgi, php-cli, apache2, libapache2-mod-fcgid
- Создает директорию `/etc/spawn-fcgi`
- Создает конфигурационный файл `/etc/spawn-fcgi/fcgi.conf` с настройками:
  - SOCKET=/var/run/php-fcgi.sock
  - OPTIONS="-u www-data -g www-data -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"
- Создает systemd service файл `/etc/systemd/system/spawn-fcgi.service`
- Перезагружает systemd и запускает сервис

**Результат:** FastCGI процесс для PHP приложений настроен и работает через systemd, создает socket для взаимодействия с веб-сервером.

### 3. Nginx с несколькими экземплярами (nginx.yml)

**Что делает playbook:**
- Устанавливает nginx
- Останавливает стандартный сервис nginx
- Создает systemd template `/etc/systemd/system/nginx@.service` для запуска нескольких экземпляров
- Создает конфигурацию `/etc/nginx/nginx-first.conf` (порт 9001, PID файл /run/nginx-first.pid)
- Создает конфигурацию `/etc/nginx/nginx-second.conf` (порт 9002, PID файл /run/nginx-second.pid)
- Перезагружает systemd и запускает оба экземпляра: nginx@first и nginx@second
- Проверяет статус обоих экземпляров

**Результат:** Два независимых экземпляра Nginx работают одновременно на портах 9001 и 9002, каждый со своей конфигурацией и PID файлом.

## Структура проекта

```
OTUS/
├── files/
│   └── log_monitor.sh          # Скрипт мониторинга логов
├── log_monitor.yml             # Playbook для мониторинга логов
├── spawn-fcgi.yml              # Playbook для spawn-fcgi
├── nginx.yml                   # Playbook для Nginx
├── invent.yml                  # Инвентарь Ansible
└── README.md                   # Документация
```

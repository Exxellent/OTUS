#!/bin/bash
if [ -f /etc/default/log-monitor ]; then
    source /etc/default/log-monitor
else
    logger "Конфигурационный файл /etc/default/log-monitor не найден"
    exit 1
fi

if [ -z "$LOG_FILE" ] || [ -z "$KEYWORD" ]; then
    logger "Необходимо задать LOG_FILE и KEYWORD в /etc/default/log-monitor"
    exit 1
fi

# Проверка лог-файла
if [ -f "$LOG_FILE" ]; then
    if grep -q "$KEYWORD" "$LOG_FILE" 2>/dev/null; then
        logger "$(date): Найдено ключевое слово '$KEYWORD' в $LOG_FILE"
    fi
else
    logger "$(date): Файл $LOG_FILE не существует"
fi

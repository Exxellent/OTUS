#! /bin/bash

set -e

IP=$1 # IP адрес клиента
DIR_EXPORT=$2 # путь к директории для экспорта

echo "Настройка сервера NFS"
echo "IP адрес клиента: $IP"
echo "Путь к директории для экспорта: $DIR_EXPORT"


apt -y install nfs-kernel-server > /dev/null 2>&1

mkdir -p "$DIR_EXPORT/upload"

chown -R nobody:nogroup "$DIR_EXPORT"
chmod 0777 "$DIR_EXPORT/upload"

echo "$DIR_EXPORT $IP/32(rw,sync,root_squash)" >> /etc/exports

exportfs -a > /dev/null 2>&1


systemctl restart nfs-kernel-server > /dev/null 2>&1


if systemctl is-active --quiet nfs-kernel-server; then
    echo "Сервис nfs-kernel-server запущен успешно"
else
    echo "Ошибка запуска сервиса nfs-kernel-server"
    exit 1
fi


echo ""
echo "Список экспортов:"
exportfs -s 

echo ""
echo "Настройка сервера NFS завершена успешно"
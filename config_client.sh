#! /bin/bash

set -e

IP=$1 # IP адрес сервера
DIR_MOUNT=$2 # путь к директории для монтирования

echo "Настройка клиента NFS"
echo "IP адрес сервера: $IP"
echo "Путь к директории для монтирования: $DIR_MOUNT"


apt -y install nfs-common > /dev/null 2>&1


EXPORTS=$(showmount -e "$IP" | tail -n +2)
EXPORT_DIR=$(echo "$EXPORTS" | awk '{print $1}')


echo "Экспортируемая директория на сервере: $EXPORT_DIR"

echo "$IP:$EXPORT_DIR $DIR_MOUNT nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab

systemctl daemon-reload > /dev/null 2>&1
systemctl restart remote-fs.target > /dev/null 2>&1



if ! mount | grep "$IP:$EXPORT_DIR" > /dev/null 2>&1; then
    echo "Directory is not mounted"
    exit 1
else
    echo "Directory is mounted"
    exit 0
fi



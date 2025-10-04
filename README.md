# Домашнее задание: Работа с NFS

## Описание задач

В данной лабораторной работе были выполнены следующие задачи:

1. Запустить 2 виртуальных машины (сервер NFS и клиента)
2. На сервере NFS подготовить и экспортировать директорию
3. В экспортированной директории создать поддиректорию `upload` с правами на запись
4. Экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab)
5. Монтирование и работа NFS на клиенте организована с использованием NFSv3
6. Написаны bash-скрипты для конфигурации серверов

---

## Решение

### 1. Установка и настройка NFS-сервера

**Установка необходимых пакетов:**

```bash
apt install nfs-kernel-server
```

**Проверка открытия портов:**

```bash
ss -tunl | grep -E "111|2049"
```

Вывод:
```
udp   UNCONN 0      0                   0.0.0.0:111        0.0.0.0:*          
udp   UNCONN 0      0                      [::]:111           [::]:*          
tcp   LISTEN 0      4096                0.0.0.0:111        0.0.0.0:*          
tcp   LISTEN 0      64                  0.0.0.0:2049       0.0.0.0:*          
tcp   LISTEN 0      4096                   [::]:111           [::]:*          
tcp   LISTEN 0      64                     [::]:2049          [::]:*
```

**Создание директории для экспорта:**

```bash
mkdir -p /srv/share/upload 
chown -R nobody:nogroup /srv/share 
chmod 0777 /srv/share/upload
```

**Настройка экспорта в `/etc/exports`:**

```bash
cat /etc/exports
```

Содержимое:
```
/srv/share 192.168.1.201/32(rw,sync,root_squash)
```

**Проверка экспортов:**

```bash
exportfs -s
```

Вывод:
```
/srv/share  192.168.1.201/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```


### 2. Настройка NFS-клиента

**Установка необходимых пакетов:**

```bash
apt install nfs-common
```

**Добавление записи в `/etc/fstab` для автоматического монтирования:**

```bash
192.168.1.200:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0
```

**Применение изменений:**

```bash
systemctl daemon-reload 
systemctl restart remote-fs.target
```

**Проверка монтирования:**

```bash
mount | grep mnt
```

Вывод:
```
systemd-1 on /mnt type autofs (rw,relatime,fd=64,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=5027)
192.168.1.200:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.1.200,mountvers=3,mountport=59989,mountproto=udp,local_lock=none,addr=192.168.1.200)
```

Проверка дискового пространства:
```bash
df -h
```

Вывод:
```
Filesystem                 Size  Used Avail Use% Mounted on
tmpfs                      319M  1.2M  318M   1% /run
/dev/sda2                   25G  7.2G   17G  31% /
192.168.1.200:/srv/share/   25G  7.2G   17G  31% /mnt
```

### 3. Проверка работоспособности

**Тестирование создания файлов:**

1. На сервере создаём тестовый файл:
   ```bash
   touch /srv/share/upload/check
   ```

2. На клиенте проверяем доступность и создаём файл:
   ```bash
   cd /mnt/upload
   ls -la  # Проверяем наличие check
   touch client
   ```

**Проверка сохранности после перезагрузки:**

1. **Тест клиента:**
   - Перезагружаем клиент
   - Проверяем наличие файлов в `/mnt/upload`

2. **Тест сервера:**
   - Перезагружаем сервер
   - Проверяем наличие файлов в `/srv/share/upload/`
   - Проверяем экспорты: `exportfs -s`

3. **Финальная проверка:**
   - Перезагружаем клиент
   - Проверяем монтирование: `mount | grep mnt`
   - Создаём финальный тестовый файл: `touch /mnt/upload/final`

**Результат проверки прав доступа:**

```bash
root@otus-2:/mnt/upload# ls -la
```

Вывод:
```
total 8
drwxrwxrwx 2 nobody nogroup 4096 Oct  4 13:13 .
drwxr-xr-x 3 nobody nogroup 4096 Oct  4 12:47 ..
-rw-r--r-- 1 nobody nogroup    0 Oct  4 13:03 client
-rw-r--r-- 1 root   root       0 Oct  4 13:13 final
-rw-r--r-- 1 root   root       0 Oct  4 12:51 test
```

---




## Баш скрипты

- [config_server.sh](config_server.sh) - скрипт автоматической настройки NFS-сервера с созданием директорий, настройкой прав доступа и экспортов.
- [config_client.sh](config_client.sh) - скрипт автоматической настройки NFS-клиента с монтированием экспортированной директории.

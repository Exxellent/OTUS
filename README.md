# Домашнее задание: Работа с LVM

## Описание задач
В данной лабораторной работе были выполнены следующие задачи:
- Уменьшение тома под / до 8G
- Выделение тома под /home
- Выделение тома под /var в mirror (зеркало)
- Настройка /home для работы со снапшотами
- Прописание монтирования в fstab с разными опциями и файловыми системами
- Работа со снапшотами: создание, удаление файлов, восстановление

---

## 1. Исходное состояние дисков

Исходное состояние дисков в системе:

``` bash
user@otus:~$ lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   25G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0   23G  0 part
  └─ubuntu--vg-ubuntu--lv 252:1    0    23G  0 lvm /
sdb                         8:16   0   50G  0 disk
sdc                         8:32   0    1G  0 disk
sdd                         8:48   0    1G  0 disk
sde                         8:64   0    1G  0 disk
sdf                         8:80   0    1G  0 disk
sr0                        11:0    1 1024M  0 rom
user@otus:~$
```

---

## 2. Уменьшение тома под / до 8G

### 2.1 Создание временного тома


```bash
root@otus:~# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
```


```bash
root@otus:~# vgcreate vg_root /dev/sdb
  Volume group "vg_root" successfully created
```


```bash
root@otus:~# lvcreate -n lv_root -l +100%FREE /dev/vg_root
WARNING: ext4 signature detected on /dev/vg_root/lv_root at offset 1080. Wipe it? [y/n]: y
  Wiping ext4 signature on /dev/vg_root/lv_root.
  Logical volume "lv_root" created.
```

### 2.2 Создание файловой системы и копирование данных


```bash
root@otus:~# mkfs.ext4 /dev/vg_root/lv_root
```


```bash
root@otus:~# mount /dev/vg_root/lv_root /mnt
```


```bash
root@otus:~# rsync -avxHAX --progress / /mnt/
```

### 2.3 Настройка GRUB


```bash
root@otus:~# for i in /proc/ /sys/ /dev/ /run/ /boot/; \
 do mount --bind $i /mnt/$i; done
```


```bash
root@otus:~# chroot /mnt/
```


```bash
root@otus:~# grub-mkconfig -o /boot/grub/grub.cfg
```



```bash
root@otus:~# update-initramfs -u
```

### 2.4 Создание нового корневого тома размером 8G


```bash
root@otus:~# lvremove /dev/ubuntu-vg/ubuntu-lv
Do you really want to remove and DISCARD active logical volume ubuntu-vg/ubuntu-lv? [y/n]: y
  Logical volume "ubuntu-lv" successfully removed.

root@otus:~# lvcreate -n ubuntu-vg/ubuntu-lv -L 8G /dev/ubuntu-vg
WARNING: ext4 signature detected on /dev/ubuntu-vg/ubuntu-lv at offset 1080. Wipe it? [y/n]: y
  Wiping ext4 signature on /dev/ubuntu-vg/ubuntu-lv.
  Logical volume "ubuntu-lv" created.
```

Создаем файловую систему и копируем данные:

```bash
root@otus:~# mkfs.ext4 /dev/ubuntu-vg/ubuntu-lv
root@otus:~# mount /dev/ubuntu-vg/ubuntu-lv /mnt
root@otus:~# rsync -avxHAX --progress / /mnt/
```

---

## 3. Выделение тома под /var в mirror (зеркало)

### 3.1 Создание зеркального тома для /var



```bash
root@otus:~# pvcreate /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.
```


```bash
root@otus:~# vgcreate vg_var /dev/sdc /dev/sdd
  Volume group "vg_var" successfully created
```


```bash
root@otus:~# lvcreate -L 950M -m1 -n lv_var vg_var
```

### 3.2 Создание файловой системы и перенос данных


```bash
root@otus:~# mkfs.ext4 /dev/vg_var/lv_var
```


```bash
root@otus:~# mount /dev/vg_var/lv_var /mnt
root@otus:~# cp -aR /var/* /mnt/
```

```bash
root@otus:~# mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
root@otus:~# umount /mnt
root@otus:~# mount /dev/vg_var/lv_var /var
```

### 3.3 Настройка автоматического монтирования

Добавляем запись в fstab:

```bash
root@otus:~# echo "`blkid | grep var: | awk '{print $2}'` \
 /var ext4 defaults 0 0" >> /etc/fstab
```

Проверяем состояние дисков после настройки /var:

```
root@otus:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   25G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0   23G  0 part
  └─ubuntu--vg-ubuntu--lv 252:6    0    8G  0 lvm  /
sdb                         8:16   0   50G  0 disk
└─vg_root-lv_root         252:0    0   50G  0 lvm
sdc                         8:32   0    1G  0 disk
├─vg_var-lv_var_rmeta_0   252:1    0    4M  0 lvm
│ └─vg_var-lv_var         252:5    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0  252:2    0  952M  0 lvm
  └─vg_var-lv_var         252:5    0  952M  0 lvm  /var
sdd                         8:48   0    1G  0 disk
├─vg_var-lv_var_rmeta_1   252:3    0    4M  0 lvm
│ └─vg_var-lv_var         252:5    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1  252:4    0  952M  0 lvm
  └─vg_var-lv_var         252:5    0  952M  0 lvm  /var
sde                         8:64   0    1G  0 disk
sdf                         8:80   0    1G  0 disk
sr0                        11:0    1 1024M  0 rom
```

---

## 4. Выделение тома под /home

### 4.1 Создание тома для /home


```bash
root@otus:~# lvcreate -n LogVol_Home -L 2G /dev/ubuntu-vg
  Logical volume "LogVol_Home" created.
```


```bash
root@otus:~# mkfs.ext4 /dev/ubuntu-vg/LogVol_Home
root@otus:~# mount /dev/ubuntu-vg/LogVol_Home /mnt/
root@otus:~# cp -aR /home/* /mnt/
root@otus:~# rm -rf /home/*
root@otus:~# umount /mnt
root@otus:~# mount /dev/ubuntu-vg/LogVol_Home /home/
```

### 4.2 Настройка автоматического монтирования


```bash
root@otus:~# echo "`blkid | grep Home | awk '{print $2}'` \
 /home xfs defaults 0 0" >> /etc/fstab
```

---

## 5. Работа со снапшотами

### 5.1 Генерация тестовых файлов

```bash
root@otus:~# touch /home/file{1..20}
```

Проверяем созданные файлы:

``` bash
root@otus:/home/user# ls -la /home
total 28
drwxr-xr-x  4 root root  4096 Sep 29 17:21 .
drwxr-xr-x 23 root root  4096 Sep 25 18:30 ..
-rw-r--r--  1 root root     0 Sep 29 17:21 file1
-rw-r--r--  1 root root     0 Sep 29 17:21 file10
-rw-r--r--  1 root root     0 Sep 29 17:21 file11
-rw-r--r--  1 root root     0 Sep 29 17:21 file12
-rw-r--r--  1 root root     0 Sep 29 17:21 file13
-rw-r--r--  1 root root     0 Sep 29 17:21 file14
-rw-r--r--  1 root root     0 Sep 29 17:21 file15
-rw-r--r--  1 root root     0 Sep 29 17:21 file16
-rw-r--r--  1 root root     0 Sep 29 17:21 file17
-rw-r--r--  1 root root     0 Sep 29 17:21 file18
-rw-r--r--  1 root root     0 Sep 29 17:21 file19
-rw-r--r--  1 root root     0 Sep 29 17:21 file2
-rw-r--r--  1 root root     0 Sep 29 17:21 file20
-rw-r--r--  1 root root     0 Sep 29 17:21 file3
-rw-r--r--  1 root root     0 Sep 29 17:21 file4
-rw-r--r--  1 root root     0 Sep 29 17:21 file5
-rw-r--r--  1 root root     0 Sep 29 17:21 file6
-rw-r--r--  1 root root     0 Sep 29 17:21 file7
-rw-r--r--  1 root root     0 Sep 29 17:21 file8
-rw-r--r--  1 root root     0 Sep 29 17:21 file9
drwx------  2 root root 16384 Sep 29 17:20 lost+found
drwxr-x---  4 user user  4096 Sep 25 18:50 user
```

### 5.2 Создание снапшота


```bash
root@otus:~# lvcreate -L 100MB -s -n home_snap \
 /dev/ubuntu-vg/LogVol_Home
```

### 5.3 Удаление части файлов

Удаляем файлы с 11 по 20:

```bash
root@otus:~# rm -f /home/file{11..20}
```

### 5.4 Восстановление из снапшота


```bash
root@otus:~# umount /home
root@otus:~# lvconvert --merge /dev/ubuntu-vg/home_snap
root@otus:~# mount /dev/mapper/ubuntu--vg-LogVol_Home /home
```

Проверяем восстановление файлов:

``` bash
root@otus:~# ls -la /home
total 28
drwxr-xr-x  4 root    root     4096 Dec 23 11:50 .
drwxr-xr-x 24 root    root     4096 Dec 23 09:49 ..
-rw-r--r--  1 root    root        0 Dec 23 11:50 file1
-rw-r--r--  1 root    root        0 Dec 23 11:50 file10
-rw-r--r--  1 root    root        0 Dec 23 11:50 file11
-rw-r--r--  1 root    root        0 Dec 23 11:50 file12
-rw-r--r--  1 root    root        0 Dec 23 11:50 file13
-rw-r--r--  1 root    root        0 Dec 23 11:50 file14
-rw-r--r--  1 root    root        0 Dec 23 11:50 file15
-rw-r--r--  1 root    root        0 Dec 23 11:50 file16
-rw-r--r--  1 root    root        0 Dec 23 11:50 file17
-rw-r--r--  1 root    root        0 Dec 23 11:50 file18
-rw-r--r--  1 root    root        0 Dec 23 11:50 file19
-rw-r--r--  1 root    root        0 Dec 23 11:50 file2
-rw-r--r--  1 root    root        0 Dec 23 11:50 file20
-rw-r--r--  1 root    root        0 Dec 23 11:50 file3
-rw-r--r--  1 root    root        0 Dec 23 11:50 file4
-rw-r--r--  1 root    root        0 Dec 23 11:50 file5
-rw-r--r--  1 root    root        0 Dec 23 11:50 file6
-rw-r--r--  1 root    root        0 Dec 23 11:50 file7
-rw-r--r--  1 root    root        0 Dec 23 11:50 file8
-rw-r--r--  1 root    root        0 Dec 23 11:50 file9
drwx------  2 root root 16384 Sep 29 17:20 lost+found
drwxr-x---  4 user user  4096 Sep 25 18:50 user
```

**Результат:** Все файлы успешно восстановлены с помощью снапшота.

---

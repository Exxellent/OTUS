# Домашнее задание: Настройка RAID и GPT разделов

## Описание задач
В данной лабораторной работе были выполнены следующие задачи:
- Добавление нескольких дисков в виртуальную машину
- Создание RAID-10 массива
- Тестирование отказоустойчивости RAID (имитация поломки и восстановление)
- Создание GPT таблицы разделов
- Создание пяти разделов и их монтирование в системе

---

## 1. Исходное состояние дисков

После добавления дисков в виртуальную машину, система видит следующие устройства:

```bash
lsblk 
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   25G  0 disk 
├─sda1   8:1    0    1M  0 part 
└─sda2   8:2    0   25G  0 part /
sdb      8:16   0    1G  0 disk 
sdc      8:32   0    1G  0 disk 
sdd      8:48   0    1G  0 disk 
sde      8:64   0    1G  0 disk 
sr0     11:0    1 1024M  0 rom  
```

**Описание:**
- `sda` - основной системный диск (25GB)
- `sdb`, `sdc`, `sdd`, `sde` - дополнительные диски по 1GB каждый для создания RAID

---

## 2. Подготовка дисков для RAID

Перед созданием RAID массива необходимо очистить суперблоки на дисках:

```bash
$ mdadm --zero-superblock --force /dev/sd{b..e}
```

---

## 3. Создание RAID-10 массива

Создаем RAID-10 массив из четырех дисков:

```bash
$ mdadm --create /dev/md0 --level=10 -n=4 /dev/sd{b..e}
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```

**Параметры:**
- `--level=10` - тип RAID (RAID-10 = зеркалирование + чередование)
- `-n=4` - количество дисков в массиве
- `/dev/sd{b..e}` - диски для использования в массиве

**Преимущества RAID-10:**
- Высокая производительность (как у RAID-0)
- Отказоустойчивость (как у RAID-1)
- Минимум 4 диска
- Допускает отказ до 2 дисков (при условии, что они не в одной паре)

---

## 4. Проверка состояния RAID массива

### Статус массива:
```bash
$ cat /proc/mdstat
Personalities : [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md0 : active raid10 sde[3] sdd[2] sdc[1] sdb[0]
      2093056 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
      
unused devices: <none>
```

### Детальная информация:
```bash
$ mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sun Sep  7 17:43:51 2025
        Raid Level : raid10
        Array Size : 2093056 (2044.00 MiB 2143.29 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Sun Sep  7 17:44:01 2025
             State : clean 
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : ubuntu:0  (local to host ubuntu)
              UUID : c0234643:99f59d89:f7d62dcc:d1a5e6f4
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       3       8       64        3      active sync set-B   /dev/sde
```

**Анализ:**
- Массив активен и работает в штатном режиме
- Все 4 диска в состоянии `[UUUU]` (Up, Up, Up, Up)
- Размер массива: ~2GB (эффективное использование 4 дисков по 1GB)
- Chunk size: 512KB для оптимальной производительности

---

## 5. Тестирование отказоустойчивости RAID

### 5.1 Имитация поломки диска

```bash
$ mdadm /dev/md0 --fail /dev/sde
mdadm: set /dev/sde faulty in /dev/md0
```

### 5.2 Проверка состояния после поломки

```bash
$ cat /proc/mdstat
Personalities : [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md0 : active raid10 sde[3](F) sdd[2] sdc[1] sdb[0]
      2093056 blocks super 1.2 512K chunks 2 near-copies [4/3] [UUU_]
      
unused devices: <none>
```

**Результат:** Диск `sde` помечен как faulty `(F)`, массив работает в деградированном режиме `[UUU_]`

### 5.3 Восстановление RAID массива

```bash
# Удаляем неисправный диск
$ mdadm /dev/md0 --remove /dev/sde
mdadm: hot removed /dev/sde from /dev/md0

# Добавляем диск обратно (имитируем замену)
$ mdadm /dev/md0 --add /dev/sde
mdadm: added /dev/sde
```

### 5.4 Проверка восстановления

```bash
$ cat /proc/mdstat
Personalities : [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md0 : active raid10 sde[4] sdd[2] sdc[1] sdb[0]
      2093056 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
      
unused devices: <none>
```

**Результат:** Массив полностью восстановлен, все диски в состоянии `[UUUU]`

---

## 6. Создание GPT таблицы разделов

Создаем пять разделов на RAID массиве с использованием GPT:

```bash
$ parted /dev/md0 mkpart primary ext4 0% 20%
$ parted /dev/md0 mkpart primary ext4 20% 40%
$ parted /dev/md0 mkpart primary ext4 40% 60%
$ parted /dev/md0 mkpart primary ext4 60% 80%
$ parted /dev/md0 mkpart primary ext4 80% 100%
```


---

## 7. Монтирование разделов

После создания разделов система автоматически их обнаружила:

```bash
$ mkdir -p /raid/part{1,2,3,4,5}
$ for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
```


```bash
lsblk
NAME      MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINTS
sda         8:0    0   25G  0 disk   
├─sda1      8:1    0    1M  0 part   
└─sda2      8:2    0   25G  0 part   /
sdb         8:16   0    1G  0 disk   
└─md0       9:0    0    2G  0 raid10 
  ├─md0p1 259:1    0  428M  0 part   /raid/part1
  ├─md0p2 259:4    0  428M  0 part   /raid/part2
  ├─md0p3 259:5    0  428M  0 part   /raid/part3
  ├─md0p4 259:8    0  428M  0 part   /raid/part4
  └─md0p5 259:9    0  330M  0 part   /raid/part5
sdc         8:32   0    1G  0 disk   
└─md0       9:0    0    2G  0 raid10 
  ├─md0p1 259:1    0  428M  0 part   /raid/part1
  ├─md0p2 259:4    0  428M  0 part   /raid/part2
  ├─md0p3 259:5    0  428M  0 part   /raid/part3
  ├─md0p4 259:8    0  428M  0 part   /raid/part4
  └─md0p5 259:9    0  330M  0 part   /raid/part5
sdd         8:48   0    1G  0 disk   
└─md0       9:0    0    2G  0 raid10 
  ├─md0p1 259:1    0  428M  0 part   /raid/part1
  ├─md0p2 259:4    0  428M  0 part   /raid/part2
  ├─md0p3 259:5    0  428M  0 part   /raid/part3
  ├─md0p4 259:8    0  428M  0 part   /raid/part4
  └─md0p5 259:9    0  330M  0 part   /raid/part5
sde         8:64   0    1G  0 disk   
└─md0       9:0    0    2G  0 raid10 
  ├─md0p1 259:1    0  428M  0 part   /raid/part1
  ├─md0p2 259:4    0  428M  0 part   /raid/part2
  ├─md0p3 259:5    0  428M  0 part   /raid/part3
  ├─md0p4 259:8    0  428M  0 part   /raid/part4
  └─md0p5 259:9    0  330M  0 part   /raid/part5
sr0        11:0    1 1024M  0 rom    
```

**Результат:**
- Все 5 разделов успешно созданы и смонтированы
- Разделы доступны по путям `/raid/part1` - `/raid/part5`
- RAID-10 обеспечивает отказоустойчивость для всех разделов

---

## 8. Автоматизация с помощью скрипта raid.sh

Для упрощения работы с RAID массивами был создан bash-скрипт `raid.sh`, который автоматизирует основные операции:

### Возможности скрипта:

- **Создание RAID массивов** различных уровней (0, 1, 5, 6, 10)
- **Автоматическая установка** необходимых пакетов (mdadm)
- **Проверка прав доступа** (требует root)
- **Валидация параметров** для каждого типа RAID
- **Создание файловых систем** (ext4, xfs, btrfs)
- **Просмотр статуса** RAID массивов
- **Отображение доступных дисков**

### Использование скрипта:

```bash
# Показать справку
./raid.sh

# Показать доступные диски
./raid.sh disks

# Создать RAID-1 массив
./raid.sh create 1 md0 /dev/sdb /dev/sdc

# Создать RAID-5 массив
./raid.sh create 5 md1 /dev/sdb /dev/sdc /dev/sdd

# Создать RAID-10 массив (как в нашей лабораторной)
./raid.sh create 10 md0 /dev/sdb /dev/sdc /dev/sdd /dev/sde

# Показать статус всех RAID массивов
./raid.sh status

# Создать файловую систему на RAID массиве
./raid.sh format /dev/md0 ext4
```

### Пример создания RAID-10 с помощью скрипта:

```bash
# 1. Показать доступные диски
./raid.sh  disks
Доступные диски:
sda    25G VBOX HARDDISK
sdb     1G VBOX HARDDISK
sdc     1G VBOX HARDDISK
sdd     1G VBOX HARDDISK
sde     1G VBOX HARDDISK



# 2. Создать RAID-10 массив
./raid.sh create 10 md0 /dev/sdb /dev/sdc /dev/sde /dev/sdd

Создание RAID 10 массива: md0
Диски: /dev/sdb /dev/sdc /dev/sde /dev/sdd
mdadm: /dev/sdb appears to be part of a raid array:
       level=raid10 devices=4 ctime=Sun Sep  7 17:43:51 2025
mdadm: /dev/sdc appears to be part of a raid array:
       level=raid10 devices=4 ctime=Sun Sep  7 17:43:51 2025
mdadm: /dev/sde appears to be part of a raid array:
       level=raid10 devices=4 ctime=Sun Sep  7 17:43:51 2025
mdadm: /dev/sdd appears to be part of a raid array:
       level=raid10 devices=4 ctime=Sun Sep  7 17:43:51 2025
Continue creating array? yes
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.

RAID 10 массив md0 создан успешно

# 3. Создать файловую систему
./raid.sh format /dev/md0 ext4

Создание файловой системы ext4 на /dev/md0
mke2fs 1.47.0 (5-Feb-2023)
Found a gpt partition table in /dev/md0
Creating filesystem with 523264 4k blocks and 130816 inodes
Filesystem UUID: 670dd5df-c1be-4171-a8ee-6cc3df8de866
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done 

Файловая система ext4 создана

# 4. Проверить статус
./raid.sh  status
Статус RAID массивов:
Personalities : [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md0 : active raid10 sdd[3] sde[2] sdc[1] sdb[0]
      2093056 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
      
unused devices: <none>```
```
### Структура скрипта:

```bash
#!/bin/bash
# Основные функции:
# - show_disks()     - отображение доступных дисков
# - create_raid()    - создание RAID массива
# - create_filesystem() - создание файловой системы
# - show_status()    - отображение статуса RAID
# - main()           - основная логика и обработка аргументов
```

---


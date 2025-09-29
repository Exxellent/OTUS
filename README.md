# Домашнее задание: Практические навыки работы с ZFS

## Описание задач

В данной лабораторной работе были выполнены следующие задачи:

1. **Определить алгоритм с наилучшим сжатием:**
   - Определить, какие алгоритмы сжатия поддерживает ZFS: `gzip`, `zle`, `lzjb`, `lz4`
   - Создать 4 файловых системы, на каждой применить свой алгоритм сжатия
   - Для сжатия использовать либо текстовый файл, либо группу файлов. Скопировать одинаковый файл в каждую файловую систему и сравнить степень сжатия с помощью команды

2. **Определить настройки пула:**
   - С помощью команды `zfs import` собрать пул ZFS
   - Командой `zfs` определить настройки:
     - Размер хранилища
     - Тип пула
     - Значение `recordsize`
     - Какое сжатие используется
     - Какая контрольная сумма используется

3. **Работа со снапшотами:**
   - Создать снапшот
   - Скопировать файл из удалённой директории
   - Восстановить файл локально
   - Найти зашифрованное сообщение в файле `secret_message`

---

## 1. Определение алгоритма с наилучшим сжатием

### Создание 4 файловых систем с разными алгоритмами сжатия

```bash
zpool create first mirror /dev/sdb /dev/sdc
zpool create second mirror /dev/sdd /dev/sde
zpool create third mirror /dev/sdf /dev/sdg
zpool create fourth mirror /dev/sdh /dev/sdi
zpool list
```

**Результат:**
```
NAME     SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
first    480M   114K   480M        -         -     0%     0%  1.00x    ONLINE  -
fourth   480M   140K   480M        -         -     0%     0%  1.00x    ONLINE  -
second   480M   122K   480M        -         -     0%     0%  1.00x    ONLINE  -
third    480M   116K   480M        -         -     0%     0%  1.00x    ONLINE  -
```

### Настройка алгоритмов сжатия

```bash
zfs set compression=lzjb first
zfs set compression=lz4 second
zfs set compression=gzip-9 third
zfs set compression=zle fourth
zfs get all | grep compression
```

**Результат:**
```
first   compression           lzjb                   local
fourth  compression           zle                    local
second  compression           lz4                    local
third   compression           gzip-9                 local
```

### Создание тестового файла для проверки сжатия

```bash
yes | head -c 40M > file

for dir in first second third fourth; do
    cp file /$dir/
done

for dir in first second third fourth; do
    ls -lah /$dir
done
```

**Результат:**
```
total 1.5M
drwxr-xr-x  2 root root    3 Sep 29 18:38 .
drwxr-xr-x 27 root root 4.0K Sep 29 18:15 ..
-rw-r--r--  1 root root  40M Sep 29 18:38 file

total 330K
drwxr-xr-x  2 root root    3 Sep 29 18:38 .
drwxr-xr-x 27 root root 4.0K Sep 29 18:15 ..
-rw-r--r--  1 root root  40M Sep 29 18:38 file

total 170K
drwxr-xr-x  2 root root    3 Sep 29 18:38 .
drwxr-xr-x 27 root root 4.0K Sep 29 18:15 ..
-rw-r--r--  1 root root  40M Sep 29 18:38 file

total 41M
drwxr-xr-x  2 root root    3 Sep 29 18:38 .
drwxr-xr-x 27 root root 4.0K Sep 29 18:15 ..
-rw-r--r--  1 root root  40M Sep 29 18:38 file
```

### Проверка использования дискового пространства

```bash
zfs list
```

**Результат:**
```
NAME     USED  AVAIL  REFER  MOUNTPOINT
first   1.61M   350M  1.43M  /first
fourth  40.2M   312M  40.0M  /fourth
second   542K   351M   350K  /second
third    378K   352M   190K  /third
```

### Анализ коэффициентов сжатия

```bash
zfs get all | grep compressratio | grep -v ref
```

**Результат:**
```
first   compressratio         27.10x                 -
fourth  compressratio         1.00x                  -
second  compressratio         102.85x                -
third   compressratio         172.78x                -
```

### Вывод

**Лучший результат показал алгоритм `gzip-9` с коэффициентом сжатия 172x**

---

## 2. Определение настроек пула

### Размер хранилища

```bash
zpool get size otus
```

**Результат:**
```
NAME  PROPERTY  VALUE  SOURCE
otus  size      480M   -
```

### Тип пула, recordsize, сжатие и контрольная сумма

```bash
zfs get type,recordsize,compression,checksum otus
```

**Результат:**
```
NAME  PROPERTY     VALUE           SOURCE
otus  type         filesystem      -
otus  recordsize   128K            local
otus  compression  zle             local
otus  checksum     sha256          local
```


## 3. Работа со снапшотами

### Скачивание файла

```bash
wget -O otus_task2.file --no-check-certificate "https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download"
```

### Восстановление файла локально

```bash
zfs receive otus/test@now < otus_task2.file
```

### Поиск секретного послания

```bash
find /otus/test -name "secret_message"
```

**Результат:**
```
/otus/test/task1/file_mess/secret_message
```

---

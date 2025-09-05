# Домашнее задание: Обновление ядра Linux

## Название задания
Обновление ядра операционной системы Linux до версии 6.16.5

## Текст задания
Выполнить обновление ядра Linux до последней стабильной версии, используя предварительно скомпилированные пакеты из официального репозитория Ubuntu mainline kernel.

## Изначальное состояние
```bash
$ uname -r
5.4.0-216-generic
```
## Основные команды

### 1. Создание рабочей директории
```bash
mkdir kernel && cd kernel
```

### 2. Загрузка необходимых пакетов ядра версии 6.16.5
```bash
# Загрузка заголовочных файлов (generic)
wget https://kernel.ubuntu.com/mainline/v6.16.5/amd64/linux-headers-6.16.5-061605-generic_6.16.5-061605.202509041605_amd64.deb

# Загрузка заголовочных файлов (общие)
wget https://kernel.ubuntu.com/mainline/v6.16.5/amd64/linux-headers-6.16.5-061605_6.16.5-061605.202509041605_all.deb

# Загрузка образа ядра
wget https://kernel.ubuntu.com/mainline/v6.16.5/amd64/linux-image-unsigned-6.16.5-061605-generic_6.16.5-061605.202509041605_amd64.deb

# Загрузка модулей ядра
wget https://kernel.ubuntu.com/mainline/v6.16.5/amd64/linux-modules-6.16.5-061605-generic_6.16.5-061605.202509041605_amd64.deb
```

### 3. Установка загруженных пакетов
```bash
sudo dpkg -i *.deb
```

### 4. Проверка содержимого директории
```bash
ls -la
```

### 5. Проверка установленных файлов в /boot
```bash
$ ls -la /boot
total 162788
drwxr-xr-x  4 root root     4096 Sep  5 15:24 .
drwxr-xr-x 19 root root     4096 Jul 14 10:24 ..
-rw-r--r--  1 root root   237889 Apr 11 19:12 config-5.4.0-216-generic
-rw-r--r--  1 root root   299505 Sep  4 16:05 config-6.16.5-061605-generic
drwxr-xr-x  4 root root     4096 Sep  5 15:24 grub
lrwxrwxrwx  1 root root       32 Sep  5 15:24 initrd.img -> initrd.img-6.16.5-061605-generic
-rw-r--r--  1 root root 92972312 Jul 14 10:21 initrd.img-5.4.0-216-generic
-rw-r--r--  1 root root 28490654 Sep  5 15:24 initrd.img-6.16.5-061605-generic
lrwxrwxrwx  1 root root       28 Jul 14 09:55 initrd.img.old -> initrd.img-5.4.0-216-generic
drwx------  2 root root    16384 Jul 14 09:54 lost+found
-rw-------  1 root root  4767839 Apr 11 19:12 System.map-5.4.0-216-generic
-rw-------  1 root root 10126845 Sep  4 16:05 System.map-6.16.5-061605-generic
lrwxrwxrwx  1 root root       29 Sep  5 15:24 vmlinuz -> vmlinuz-6.16.5-061605-generic
-rw-------  1 root root 13714184 Apr 11 19:21 vmlinuz-5.4.0-216-generic
-rw-------  1 root root 16032256 Sep  4 16:05 vmlinuz-6.16.5-061605-generic
lrwxrwxrwx  1 root root       25 Jul 14 09:55 vmlinuz.old -> vmlinuz-5.4.0-216-generic
```
*Ожидаемый результат: появление новых файлов ядра версии 6.16.5 в директории /boot*

### 6. Обновление конфигурации загрузчика GRUB
```bash
sudo update-grub
```
*Команда обновляет конфигурацию GRUB и добавляет новое ядро в меню загрузки*

### 7. Установка нового ядра по умолчанию
```bash
sudo grub-set-default 0
```
*Устанавливает первый пункт меню GRUB (новое ядро) как загружаемый по умолчанию*

## Результат выполнения

После выполнения всех команд система будет настроена на загрузку с новым ядром версии 6.16.5. Для применения изменений необходима перезагрузка системы.

Проверить успешность установки можно командой:
```bash
$ uname -a
Linux alertix 6.16.5-061605-generic #202509041605 SMP PREEMPT_DYNAMIC Thu Sep  4 19:51:27 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
```

## Заметки

1. **Зависимости**: Команда `dpkg -i *.deb` может потребовать разрешения зависимостей. При возникновении ошибок используйте:
   ```bash
   sudo apt-get install -f
   ```

2. **Откат**: В случае проблем можно выбрать предыдущую версию ядра в меню GRUB при загрузке системы.

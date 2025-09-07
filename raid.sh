#!/bin/bash

# Простой скрипт для создания RAID массивов
set -e

if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: Запустите скрипт с правами root"
    exit 1
fi

if ! command -v mdadm &> /dev/null; then
    echo "Установка mdadm..."
    apt-get update && apt-get install -y mdadm
fi

show_disks() {
    echo "Доступные диски:"
    lsblk -d -n -o NAME,SIZE,MODEL | grep -E "sd|nvme|hd"
}

create_raid() {
    local level="$1"
    local raid_name="$2"
    shift 2
    local devices=("$@")
    local num_devices=${#devices[@]}
    
    echo "Создание RAID $level массива: $raid_name"
    echo "Диски: ${devices[*]}"
    
    case $level in
        0) [[ $num_devices -lt 2 ]] && { echo "Ошибка: RAID 0 требует минимум 2 диска"; exit 1; } ;;
        1) [[ $num_devices -ne 2 ]] && { echo "Ошибка: RAID 1 требует ровно 2 диска"; exit 1; } ;;
        5) [[ $num_devices -lt 3 ]] && { echo "Ошибка: RAID 5 требует минимум 3 диска"; exit 1; } ;;
        6) [[ $num_devices -lt 4 ]] && { echo "Ошибка: RAID 6 требует минимум 4 диска"; exit 1; } ;;
        10) [[ $num_devices -lt 4 ]] || [[ $((num_devices % 2)) -ne 0 ]] && { echo "Ошибка: RAID 10 требует четное количество дисков (минимум 4)"; exit 1; } ;;
    esac
    
    mdadm --create /dev/$raid_name --level=$level --raid-devices=$num_devices "${devices[@]}"
    echo "RAID $level массив $raid_name создан успешно"
}

create_filesystem() {
    local device="$1"
    local fstype="${2:-ext4}"
    
    echo "Создание файловой системы $fstype на $device"
    case $fstype in
        ext4) mkfs.ext4 -F "$device" ;;
        xfs) mkfs.xfs -f "$device" ;;
        btrfs) mkfs.btrfs -f "$device" ;;
        *) echo "Ошибка: Неподдерживаемый тип файловой системы: $fstype"; exit 1 ;;
    esac
    echo "Файловая система $fstype создана"
}

show_status() {
    echo "Статус RAID массивов:"
    cat /proc/mdstat
}

main() {
    if [[ $# -eq 0 ]]; then
        echo "Использование:"
        echo "  $0 create <level> <name> <devices...>  - создать RAID"
        echo "  $0 status                              - показать статус"
        echo "  $0 disks                               - показать диски"
        echo "  $0 format <device> [filesystem]       - создать файловую систему"
        echo ""
        echo "Примеры:"
        echo "  $0 create 1 md0 /dev/sdb /dev/sdc"
        echo "  $0 create 5 md1 /dev/sdb /dev/sdc /dev/sdd"
        echo "  $0 format /dev/md0 ext4"
        exit 1
    fi
    
    case $1 in
        "create")
            if [[ $# -lt 4 ]]; then
                echo "Ошибка: Недостаточно параметров для создания RAID"
                exit 1
            fi
            create_raid "$2" "$3" "${@:4}"
            ;;
        "status") show_status ;;
        "disks") show_disks ;;
        "format")
            if [[ $# -lt 2 ]]; then
                echo "Ошибка: Укажите устройство для форматирования"
                exit 1
            fi
            create_filesystem "$2" "$3"
            ;;
        *) echo "Неизвестная команда: $1" ;;
    esac
}

main "$@"
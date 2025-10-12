# Домашнее задание: Сборка RPM-пакета и создание репозитория

## Описание задач

В данной лабораторной работе были поставлены следующие задачи:

1. Создать свой RPM пакет (можно взять свое приложение, либо собрать, например, Apache с определенными опциями)
2. Создать свой репозиторий и разместить там ранее собранный RPM

---

## Примечание

Так как под рукой отсутствовал дистрибутив с пакетным менеджером RPM, сборка пакета была выполнена на Ubuntu 22.04


## Решение

### 1. Сборка своего RPM пакета

1. Установим инструменты для сборки RPM:

```bash
sudo apt update
sudo apt install rpm createrepo-c
```

2. Создадим структуру каталогов для rpmbuild:
```bash
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
```

3. Создадим простой скрипт, который будет выводить "Hello otus!":
```bash
mkdir ~/hello-rpm
echo -e '#!/bin/bash\necho "Hello otus!"' > ~/hello-rpm/hello.sh
chmod +x ~/hello-rpm/hello.sh
tar czvf ~/rpmbuild/SOURCES/hello-rpm.tar.gz -C ~/ hello-rpm
```

4. Создадим спецификацию для RPM пакета:

```spec
Name:           hello-rpm
Version:        1.0
Release:        1%{?dist}
Summary:        Hello otus! 

License:        MIT
Source0:        hello-rpm.tar.gz
BuildArch:      noarch

%description
Просто тестовый скрипт для сборки RPM

%prep
%setup -q -n hello-rpm

%build

%install
mkdir -p %{buildroot}/usr/local/bin
cp hello.sh %{buildroot}/usr/local/bin/hello-rpm

%files
/usr/local/bin/hello-rpm

%changelog
* Sun Oct 12 2025 Renat - 1.0-1
- Initial RPM
```

5. Сборка пакета:

```bash
rpmbuild -ba ~/rpmbuild/SPECS/hello-rpm.spec
```

6. Тест пакета на Ubuntu:
```bash
root@otus-2:~/rpmbuild/SPECS# sudo alien -i /root/rpmbuild/RPMS/noarch/hello-rpm-1.0-1.noarch.rpm
root@otus-2:~/rpmbuild/SPECS# hello-rpm 
Hello otus!
```


### 2. Создание своего репозитория

1. Создание директории для репозитория:
```bash
mkdir -p ~/myrepo
cp ~/rpmbuild/RPMS/noarch/*.rpm ~/myrepo/
createrepo_c ~/myrepo
```

2. Копирование репозитория в каталог nginx:
```bash
sudo cp -r ~/myrepo/* /var/www/html/myrepo/
sudo systemctl restart nginx
```

3. Проверка доступности репозитория:
```bash
root@otus-2:~/myrepo/repodata# curl http://localhost/myrepo/
<html>
<head><title>Index of /myrepo/</title></head>
<body>
<h1>Index of /myrepo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          12-Oct-2025 16:23       -
<a href="hello-rpm-1.0-1.noarch.rpm">hello-rpm-1.0-1.noarch.rpm</a>                         12-Oct-2025 16:25    6413
</pre><hr></body>
</html>
```

4. Тест с браузера:
![Фото](img/image.png)

## Результат
Пакет успешно собирается, устанавливается и работает корректно, выводя сообщение "Hello otus!" при запуске команды `hello-rpm`.
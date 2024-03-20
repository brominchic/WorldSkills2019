# WorldSkills2019
# Задание:
Установить Terraform на ControlVM 

Выполнение:
ControlVM:
>
>
Устанавляваем wget и unzip:
>
   sudo -i
>
>
   apt-get update && apt-get install -y wget unzip
>
>
Скачиваем архив с Terraform:
с Зеркала Яндекса:
>
   wget https://hashicorp-releases.yandexcloud.net/terraform/1.7.2/terraform_1.7.2_linux_amd64.zip
>
>
с Зеркала VK Cloud, если не работает Яндекс
>
   wget https://hashicorp-releases.mcs.mail.ru/terraform/1.7.3/terraform_1.7.3_linux_amd64.zip
>
>
Распаковываем его в каталог /usr/local/bin:
>
   unzip  terraform_1.7.3_linux_amd64.zip -d /usr/local/bin/
>
>
Проверяем:
>
>
terraform --version
>
>
Подготовка облачной инфраструктуры
>
>
1. Подготовьте сценарий автоматизации развёртывания облачной инфраструктуры.
>
>
1. Виртуальные машины и сети должны быть созданы согласно Топологии.
2. Имена виртуальных машин и сетей должны соответствовать Топологии.
3. Обеспечьте подключение виртуальных машин к соответствующим сетям.
4. В случае предоставления внешнего доступа к созданным виртуальным машинам, он должен быть разрешён только по протоколу ssh.
5. Разрешите трафик по протоколу ICMP.
6. Вы можете назначить глобальные IP адреса для управления созданными виртуальными машинами.
7. Используйте аутентификацию на основе открытых ключей, аутентификация с использованием пароля должна быть отключена для SSH.
8. Создайте балансировщик нагрузки
>
1. Сохраните внешний адрес балансировщика нагрузки в файле /home/altlinux/lb.ip.
2. Ограничьте внешний доступ протоколами http и https.
3. Балансировка нагрузки должна использовать алгоритм round robin.
4. При обращении на внешний адрес балансировщика нагрузки должен выводиться ответ от приложения на внутреннем сервере.
>
>
2. Виртуальные машины должны соответствовать следующим характеристикам.
>
>
1. Операционная система: ALT Linux 10.
2. Количество vCPU: 1.
3. Объём оперативной памяти: 1024 МБ.
4. Объём диска: 15 ГБ.
5. Тип диска: HDD.
6. Разместите виртуальные машины в регионе Москва.
7. Разместите Web1 в зоне доступности ru-central1-a.
8. Разместите Web2 в зоне доступности ru-central1-b.
>
>
3. На машине ControlVM создайте скрипт cloudinit.sh.
>
>
1. В качестве рабочей директории используйте путь /home/altlinux/bin.
2. Используйте файл /home/altlinux/bin/cloud.conf для указания настроек для подключения к облачному провайдеру.
>
>
>
1. При выполнении проверки, эксперты могут изменить настройки только в файле cloud.conf. Другие файлы редактироваться не будут.
2. Вы можете оставить любые понятные комментарии в файле cloud.conf.
>
>
3. Скрипт должен выполняться из любой директории без явного указания пути к исполняемому файлу.
4. Выполнение задания ожидается с использованием инструментов Terraform и/или OpenStack CLI. Однако, вы вправе выбрать другие инструменты, не противоречащие условиям задания и правилам соревнования.
>
>
ВЫПОЛНЕНИЕ:
>
>
Создаём рабочию директорию по пути "/home/altlinux/bin" и переходим в неё:
>
>
mkdir ~/bin; cd ~/bin
>
>
Создадим файл в каталоге пользователя, под которым мы работаем и будем запускать сценарий:
документация от Яндекс
>
>
vim ~/.terraformrc
>
>
данное содержимое вставляем без изменений. По умолчанию, установка провайдера выполняется из репозитория hashicorp, однако, он может быть заблокирован на территории России, поэтому мы переопределяем путь по которому выполняются запрос
>
>
                provider_installation {
                  network_mirror {
                    url = "https://terraform-mirror.yandexcloud.net/"
                    include = ["registry.terraform.io/*/*"]
                  }
                  direct {
                    exclude = ["registry.terraform.io/*/*"]
                  }
                }
>
>
Создаём рабочию директорию по пути "/home/altlinux/bin" и переходим в неё:
>
>
          mkdir ~/bin; cd ~/bin
>
>
Создадим файл variables.tf и опишем основные переменные которые потребуются:
>
>
          vim variables.tf
>
>
содержимое:
>
>
            variable "token" {
                type      = string
                sensitive = true
            }
            
            variable "cloud_id" {
                type      = string
                sensitive = true
            }
            
            variable "folder_id" {
                type      = string
                sensitive = true
            }
>
>
В файле main.tf - опишем конфигурацию для создания всех необходимых ресурсов:
>
>
        vim main.tf
>
>
содержимое:
>
>
              terraform {
                required_providers {
                  yandex = {
                    source = "yandex-cloud/yandex"
                  }
                }
                required_version = ">= 0.13"
              }
              
              provider "yandex" {
                token     = var.token
                cloud_id  = var.cloud_id
                folder_id = var.folder_id
              }
              
              resource "yandex_compute_instance" "web1" {
                name        = "web1"
                hostname    = "web1"
                platform_id = "standard-v1"
                zone        = "ru-central1-a"
              
                resources {
                  cores  	  = 2
                  memory 	  = 1
                  core_fraction = 20
                }
              
                boot_disk {
                  initialize_params {
              	image_id = "fd8i8fljrbbcclckhlm9"
              	size	 = 15
              	type	 = "network-hdd"
                  }
                }
              
                network_interface {
                  subnet_id  = "${yandex_vpc_subnet.subnet_web1.id}"
                  ip_address = "192.168.100.100"
                  nat	       = true
                }
              
                metadata = {
                  ssh-keys = "altlinux:${file("~/.ssh/id_rsa.pub")}"
                }
              
                timeouts {
                  create="10m"
                }
              }
              
              resource "yandex_compute_instance" "web2" {
                name        = "web2"
                hostname    = "web2"
                platform_id = "standard-v1"
                zone        = "ru-central1-b"
              
                resources {
                  cores  	  = 2
                  memory 	  = 1
                  core_fraction = 20
                }
              
                boot_disk {
                  initialize_params {
              	image_id = "fd8i8fljrbbcclckhlm9"
              	size	 = 15
              	type	 = "network-hdd"
                  }
                }
              
                network_interface {
                  subnet_id          = "${yandex_vpc_subnet.subnet_web2.id}"
                  ip_address 	       = "192.168.200.100"
                  nat	               = true
                }
              
                metadata = {
                  ssh-keys = "altlinux:${file("~/.ssh/id_rsa.pub")}"
                }
              
                timeouts {
                  create="10m"
                }
              }
              
              resource "yandex_vpc_network" "network_web" {
                name = "network_web"
              }
              
              resource "yandex_vpc_subnet" "subnet_web1" {
                zone           = "ru-central1-a"
                network_id     = "${yandex_vpc_network.network_web.id}"
                v4_cidr_blocks = ["192.168.100.0/24"]
              }
              
              resource "yandex_vpc_subnet" "subnet_web2" {
                zone           = "ru-central1-b"
                network_id     = "${yandex_vpc_network.network_web.id}"
                v4_cidr_blocks = ["192.168.200.0/24"]
              }
              
              resource "yandex_lb_network_load_balancer" "lb-web" {
                name = "lb-web"
              
                listener {
                  name = "http"
                  port = 80
                  external_address_spec {
                    ip_version = "ipv4"
                  }
                }
              
                listener {
                  name = "https"
                  port = 443
                  external_address_spec {
                    ip_version = "ipv4"
                  }
                }
              
                attached_target_group {
                  target_group_id = "${yandex_lb_target_group.lb-group.id}"
              
                  healthcheck {
                    name = "http"
                    http_options {
                      port = 80
                      path = "/"
                    }
                  }
                }
              }
              
              resource "yandex_lb_target_group" "lb-group" {
                name      = "lb-group"
              
                target {
                  subnet_id = "${yandex_vpc_subnet.subnet_web1.id}"
                  address   = "${yandex_compute_instance.web1.network_interface.0.ip_address}"
                }
              
                target {
                  subnet_id = "${yandex_vpc_subnet.subnet_web2.id}"
                  address   = "${yandex_compute_instance.web2.network_interface.0.ip_address}"
                }
              }
              
              output "lb_ip" {
                value = yandex_lb_network_load_balancer.lb-web
              }
>
>
Файл /home/altlinux/bin/cloud.conf используем для указания настроек для подключения к облачному провайдеру:
>
>
              vim cloud.conf
>
>
содержимое:
>
>
        # Yandex Token
        export TF_VAR_token=<ВСТАВЛЯЕМ СОДЕРЖИМОЕ ДЛЯ ТЕКУЩЕГО АККАУНТА В YANDEX CLOUD>
        
        # Yandex Cloud ID
        export TF_VAR_cloud_id=<ВСТАВЛЯЕМ СОДЕРЖИМОЕ ДЛЯ ТЕКУЩЕГО АККАУНТА В YANDEX CLOUD>
        
        # Yandex Project ID
        export TF_VAR_folder_id=<ВСТАВЛЯЕМ СОДЕРЖИМОЕ ДЛЯ ТЕКУЩЕГО АККАУНТА В YANDEX CLOUD>
        Создаём файл cloudinit.sh для запуска всего вышеописанного:
>
>
vim cloudinit.sh
>
>
содержимое:
>
>
          #!/bin/bash
          
          cd /home/altlinux/bin
          source cloud.conf
          terraform init
          terraform apply -auto-approve
          terraform output | grep -E '"address" = "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"' > 
          /home/altlinux/lb.ip
>
>
Задаём права на исполнение:
>
>
          chmod +x cloudinit.sh
>
>
Задаём возможность скрипту cloudinit.sh выполняться из любой директории без явного указания пути к исполняемому файлу:
>
>
          export PATH=$PATH:/home/altlinux/bin
>
>
Генерируем ssh-ключи:
>
>
          ssh-keygen -t rsa
>
>
Выходим из текущего каталога /home/altlinux/bin в домашний каталог пользователя и пытаемся запустить скрипт:
>
>
          cd
>
>
          cloudinit.sh
>
>
результат - начало:
>
>
https://sysahelper.ru/pluginfile.php/273/mod_page/content/14/image%20%2810%29.png
>
>
результат - конец:
>
>
https://sysahelper.ru/pluginfile.php/273/mod_page/content/14/image%20%2811%29.png
>
>
также в файл /home/altlinux/lb.ip сохранена информацию о внешнем IP-адресе 
>
>
https://sysahelper.ru/pluginfile.php/273/mod_page/content/14/image%20%2817%29.png
>
>
Результат созданных ресурсов в панеле Yandex Cloud:
>
https://sysahelper.ru/pluginfile.php/273/mod_page/content/14/image%20%2815%29.png
>
>
>
>
>
>
>
>
Развертывание приложений в Docker - установка Docker и Docker Compose, создание локального Docker Registry
>
>
Задание:
>
>
1. На машине ControlVM.
>
>
1. Установите Docker и Docker Compose.
2. Создайте локальный Docker Registry.
>
>
Выполнение:
>
>
ControlVM:
>
>
Устанавливаем Docker и Docker Compose:
>
>
      sudo apt-get update && sudo apt-get install -y docker-{ce,compose}
>
>
Включаем и добавляем в автозагрузку службу docker:
>
>
      sudo systemctl enable --now docker.service
>
>
Добавляем пользователя altlinux в группу docker:
>
>
      sudo usermod -aG docker altlinux
>
>
Завершаем текуший сеанс пользователя altlinux:
>
>
      exit
>
>
Подлючаемся к ControlVM вновьи проверяем запуск команд docker от пользователя altlinux:
>
>
https://sysahelper.ru/pluginfile.php/304/mod_page/content/2/image.png
>
>
Создаём и запускаем локальный Docker Registry:
поднимает контейнер Docker с именем DockerRegistry из образа registry:2. Контейнер будет слушать сетевые запросы на порту 5000, а параметр --restart=always позволит автоматически запускаться контейнеру после перезагрузки сервера.
>
>
      docker run -d -p 5000:5000 --restart=always --name DockerRegistry registry:2
>
>
Проверяем:
>
>
https://sysahelper.ru/pluginfile.php/304/mod_page/content/2/image%20%281%29.png

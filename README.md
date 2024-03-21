https://antoshabrain.blogspot.com/2021/12/docker-nextcloud-postgres-redis-amd64.html?ysclid=lu0x8sogai359872535
https://anasdidi.dev/articles/200713-docker-compose-postgres/#docker-compose-file
https://www.heyvaldemar.net/ustanovka-minecraft-server-s-ispolzovaniem-docker-compose/
https://github.com/heyValdemar/minecraft-server-docker-compose

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

# Развертывание приложений в Docker - Dockerfile для приложения HelloFIRPO
# Задание:
3. В домашней директории хоста создайте файл name.txt и запишите в него строку experts.
>
4. Напишите Dockerfile для приложения HelloFIRPO.
>
>1. В качестве базового образа используйте alpine
>2. Сделайте рабочей директорию /hello и скопируйте в неё name.txt
>3. Контейнер при запуске должен выполнять команду echo, которая выводит сообщение "Hello, >FIRPO! Greetings from " и затем содержимое файла name.txt, после чего завершать свою работу

   
5. Соберите образ приложения App и загрузите его в ваш Registry.

>1. Используйте номер версии 1.0 для вашего приложения
>2. Образ должен быть доступен для скачивания и дальнейшего запуска на локальной машине.
# Выполнение:
>Создаём в домашней директории из под пользователя altlinux файл name.txt и записываем в него >строку experts:
>
         echo  "experts" > ~/name.txt
Создаём Dockerfile для приложения HelloFIRPO:
>
         vim Dockerfile
содержимое:
>
            FROM alpine
            
            WORKDIR /hello
            
            COPY name.txt ./
            
            CMD echo "Hello, FIRPO! Greetings from $(cat name.txt)"
>

где:

FROM - задаёт базовый образ;

WORKDIR - задаёт рабочию директорию внутри контейнера;

COPY - копирует файл с локального хоста в рабочию директорию контейнера;

CMD - определяем команду, которую необходимо будет выполнить после запуска контейнера, после чего контейнер будет остановлен

Выполняем сборку образа:
>
>-t - позволяет присвоить имя собираемому образу;
>"." - говорит о том что Dockerfile находится в текущей директории откуда выполняется данная >команда и имеет имя именно Dockerfile:
>
         docker build -t app .
>результат:
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/20.png)
>
Проверяем:
>наличие собранного образа:
>
      docker images
>
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/21.png)
>
запуск контейнера, что он выводит необходимое содержимое:
>
         docker run --name HelloFIRPO app
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/22.png)

Удаляем контейнер:
>
         docker rm HelloFIRPO
загружаем образ собранный из Dockerfile в локальной DockerRegistry:
присваиваем тег для размещения образа в локальном Docker Registry:
>
         docker tag app localhost:5000/app:1.0
Загружаем образ в локальный Docker Registry:
>
         docker push localhost:5000/app:1.0
Результат:

![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/23.png)
Проверяем:
>наличие образа:
>
         docker images
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/24.png)

и возможность загрузки из локального Docker Registry:
перед - удаляем образы localhost:5000/app:1.0 и app:
>
         docker rmi localhost:5000/app:1.0 app

>
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/25.png)
>
загружаем образ приложения HelloFIRPO из локального Docker Registry:
>
         docker pull localhost:5000/app:1.0
>
>
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/27.png)
Также проверяем возможность запуска приложения из скаченного образа из локального репозитория:
>
>
         docker run --name HelloFIRPO localhost:5000/app:1.0
>
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/28.png)
>
# Развёртывания облачных сервисов - Подготовьте web-приложение App1
# Задание:
2. Подготовьте web-приложение App1
>1. Скачайте файлы app1.py и Dockerfile по адресу:
>https://github.com/auteam-usr/moscow39
>2. Соберите образ приложения и загрузите его в любой репозиторий Docker на ваше усмотрение.
# Выполнение:
# ControlVM:
>Устанавливаем git:
>
         sudo apt-get install -y git
>Клонируем репозиторий по ссылке с задания:
>
         git clone https://github.com/auteam-usr/moscow39.git
результат:
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/1.png)
>
>Переходим в директорию moscow39:
>
      cd moscow39
>Выполняем сборку образа:
>-t - позволяет присвоить имя собираемому образу;
>>"." - говорит о том что Dockerfile находится в текущей директории откуда выполняется данная команда и имеет имя именно Dockerfile:
>
         docker build -t app1 .
результат:

![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/2.png)
Проверяем:
>наличие собранного образа:
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/3.png)
загружаем образ собранный из Dockerfile в свой аккаунт на hub.docker.com:
>переходим в свой аккаунт на hub.docker.com - нажимаем Repositories -> Create задаём Repository Name и >нажимаем Create:
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/4.png)
>Далее переходим в настройки аккаунта на вкладку Security и нажимаем NewAccess Token:
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/5.png)
>вводим имя для Access Token и нажимаем Generate:
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/6.png)
>нажимаем Copy and Close:
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/7.png)
>результат:
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/8.png)
на ControlVM выполняем вход в свой аккаунт на hub.docker.com на основе логина и только что соданного и скопированного токена:
>
         docker login -u newerr0r
в качестве пароля передаём содержимое скопированного токена
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/9.png)
присваиваем тег собранному образу:
>
      docker tag app1 newerr0r/app1:1.0
загружаем в наш аккаунт:
>
      docker push newerr0r/app1:1.0
результат:
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/10.png)
также проверяем в веб-интерфейсе в своём аккаунте:
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/11.png)
# Развёртывания облачных сервисов - DeployApp.sh должна запускать средства автоматизации
Задание:
1. На машине ControlVM создайте скрипт /home/altlinux/bin/DeployApp.sh.

>1. Скрипт должен выполняться из любой директории без явного указания пути к исполняемому файлу
>3. Команда DeployApp.sh должна запускать средства автоматизации для настройки операционных систем.
>>1. Разверните web-приложение App1 из репозитория Docker на виртуальных машинах Web1 и Web2.
>>2. Обеспечьте балансировку нагрузки между Web1 и Web2.
>>3. Обеспечьте внешний доступ к web-приложению по протоколу https.
>>4. При обращении по протоколу http должно выполняться автоматическое перенаправления на протокол https.
>>5. Обеспечивать доверие сертификату не требуется.
# Выполнение:
# ControlVM:
Установим ansible:
>
         sudo apt-get install -y ansible
Создадим директорию под ansible:
>
         mkdir ansible
Правим основной файл terraform по пути /home/altlinux/bin/main.tf и добавляем следующую информацию:
>
         vim ~/bin/main.tf
данный блок будет на основе шаблона автоматически после разрёртывания инфраструктуры с помощью cloudinit.sh - будет создавать инвентарный файл для ansible:
>
         data "template_file" "inventory" {
             template = file("./_templates/inventory.tpl")
           
             vars = {
                 user = "altlinux"
                 web1 = join("", [yandex_compute_instance.web1.name, " ansible_host=", yandex_compute_instance.web1.network_interface.0.nat_ip_address])
                 web2 = join("", [yandex_compute_instance.web2.name, " ansible_host=", yandex_compute_instance.web2.network_interface.0.nat_ip_address])
             }
         }
         
         resource "local_file" "save_inventory" {
            content  = data.template_file.inventory.rendered
            filename = "/home/altlinux/ansible/inventory"
         }
Создаём директорию для шаблона:
>
         mkdir ~/bin/_templates/
Теперь создаём сам шаблон для инвентарного файла:
>
         vim ~/bin/_templates/inventory.tpl
содержимое:
>
         ${web1}
         ${web2}
         
         [all:vars]
         ansible_user = ${user}
         ansible_ssh_extra_args = '-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
         ansible_python_interpreter = /usr/bin/python3
> Пишем playbook-сценарий, который будет развёртывать и настроивать web1 и web2:
> 
         vim ~/ansible/playbook.yml
>содержимое:
>
         ---
         - hosts: all
           remote_user: altlinux
           become: true
         
           tasks:
             - name: Install docker
               apt_rpm:
                 name:
                   - docker-ce
                   - python3-module-pip
                 state: present
                 update_cache: true
               ignore_errors: true
         
             - name: Started and enabled docker
               systemd:
                 name: docker
                 state: started
                 enabled: true
         
             - name: Install docker-py
               command:
                 cmd: pip3 install docker-py
         
             - name: Start a container App1
               docker_container:
                 name: app1
                 hostname: "{{ ansible_hostname }}"
                 image: newerr0r/app1:1.0
                 ports:
                   - "80:80"
Создаём скрипт по пути /home/altlinux/bin/DeployApp.sh:
>
         vim /home/altlinux/bin/DeployApp.sh
содержимое:
>
         #!/bin/bash
         
         cd /home/altlinux/ansible
         ansible-playbook -i inventory playbook.yml
Задаём права на исполнение:
>
         chmod +x /home/altlinux/bin/DeployApp.sh
Запускаем скрипт:
>
         DeployApp.sh


результат:
![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/15.png)
>Проверяем:

>>из файла /home/altlinux/lb.ip берём внешний адрес Балансировщика и проверяем в браузере доступ:

![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/16.png)

доступ:

![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/17.png)

при обновлении страницы видна пработа балансировщика:

![изображение](https://github.com/brominchic/WorldSkills2019/blob/main/18.png)

#!/bin/bash
path="/etc/network/interfaces"
nbr=5 # количество мостов на этом стенде

function deploy_bridges_templates {                         #Функция для создание сетевых адаптеров

    for (( br=1001; br <= $(($nst * $nbr + 1000)); br++ ))
    do
        echo >> $path
        echo "auto vmbr$br" >> $path
        echo "iface vmbr$br inet manual" >> $path
        echo "	bridge-ports none" >> $path
        echo "	bridge-stp off" >> $path
        echo "	bridge-fd 0" >> $path 
        echo >> $path
        echo "Мост vmbr$br создан";
    done
    
   sleep 1
    systemctl restart networking
}

function download_template {                                #Функция для загрузки бекабов машин и создание шаблонов

echo "Установка программного обеспечения, ожидайте"
{
apt update;
apt-get install python3-pip python3-venv -y;
python3 -m venv myenv;
source myenv/bin/activate;
pip3 install wldhx.yadisk-direct;
}&>/dev/null
echo "DONE!!!"
echo "Загрузка образа сервера"
# shellcheck disable=SC2046
curl -L $(yadisk-direct https://disk.yandex.ru/d/jpt_XrxLm04HYA) -o vzdump-qemu-100-2024_03_17-20_54_28.vma.gz
echo "DONE!!!"
echo "Настройка шаблона сервера"
mv vzdump-qemu-100-2024_03_17-20_54_28.vma.gz /var/lib/vz/dump/
qmrestore local:backup/vzdump-qemu-100-2024_03_17-20_54_28.vma.gz 999
rm /var/lib/vz/dump/vzdump-qemu-100-2024_03_17-20_54_28.vma.gz
qm template 999
echo "DONE!!!"
echo "Загрузка образа клиента"
# shellcheck disable=SC2046
curl -L $(yadisk-direct https://disk.yandex.ru/d/1-3wMk1oy60_BA) -o vzdump-qemu-100-2024_03_24-13_16_07.vma.gz
echo "DONE!!!"
echo "Настройка шаблона клиента"
mv vzdump-qemu-100-2024_03_24-13_16_07.vma.gz /var/lib/vz/dump/
qmrestore local:backup/vzdump-qemu-100-2024_03_24-13_16_07.vma.gz 998
rm /var/lib/vz/dump/vzdump-qemu-100-2024_03_24-13_16_07.vma.gz
qm template 998
echo "Шаблоны виртуальных машин настроены!!!!"

}

# shellcheck disable=SC2120
function deploy_stand {                                     #функция для создания машин (1 стенд)
    echo "Создание машин для рабочего места $i из шаблонов"
{       nvm=$((1000 + 10 * $i))
        nvm1=$((1000 + 10 * $i + 1))
        nvm2=$((1000 + 10 * $i + 2))
        nvm3=$((1000 + 10 * $i + 3))
        nvm4=$((1000 + 10 * $i + 4))
        nvm5=$((1000 + 10 * $i + 5))
        br1=vmbr$(($nbr * $i + 1001))
        br2=vmbr$(($nbr * $i + 1002))
        br3=vmbr$(($nbr * $i + 1003))
        br4=vmbr$(($nbr * $i + 1004))
        br5=vmbr$(($nbr * $i + 1005))
#Клонирование шаблонов
qm clone 999 $nvm --name "ISP"                  #создается СВЯЗАННЫЙ клон, если хотите создать не связанный добавьте ключ --full
qm clone 999 $nvm1 --name "HQ-R"                #создается СВЯЗАННЫЙ клон, если хотите создать не связанный добавьте ключ --full
qm clone 999 $nvm2 --name "BR-R"                #создается СВЯЗАННЫЙ клон, если хотите создать не связанный добавьте ключ --full
qm clone 999 $nvm3 --name "HQ-SRV"              #создается СВЯЗАННЫЙ клон, если хотите создать не связанный добавьте ключ --full
qm clone 999 $nvm4 --name "BR-SRV"              #создается СВЯЗАННЫЙ клон, если хотите создать не связанный добавьте ключ --full
qm clone 998 $nvm5 --name "CLI"                 #создается СВЯЗАННЫЙ клон, если хотите создать не связанный добавьте ключ --full
#Настраиваются апаратные части виртуальных машин
qm set $nvm --ide2 none --net1 virtio,bridge=$br1 --net2 virtio,bridge=$br2 --net3 virtio,bridge=$br3 --tags DE_stand_user$nvm
qm set $nvm1 --ide2 none --net0 virtio,bridge=$br3 --net1 virtio,bridge=$br5 --tags DE_stand_user$nvm
qm set $nvm2 --ide2 none --net0 virtio,bridge=$br2 --net1 virtio,bridge=$br4 --tags DE_stand_user$nvm
qm set $nvm3 --ide2 none --net0 virtio,bridge=$br5 --tags DE_stand_user$nvm
qm set $nvm4 --ide2 none --net0 virtio,bridge=$br4 --virtio1 local-lvm:1 --virtio2 local-lvm:1 --virtio3 local-lvm:1 --tags DE_stand_user$nvm
qm set $nvm5 --ide2 none --net0 virtio,bridge=$br1 --tags DE_stand_user$nvm --cdrom none
qm start $nvm                                   #Запуск ISP
qm start $nvm5                                  #Запуск CLI
}&>/dev/null
echo "развертывание машин для рабочего места $i завершено"
#Время ожидания запуска машин, если у вас быстрые диски
sleep 60        #можно уменьшить данный параметр. Время 
#указано в секундах.
echo "Настройка сетевых параметров ISP для рабочего места $i"
qm guest exec $nvm -- bash -c "cp -R /etc/net/ifaces/ens18 /etc/net/ifaces/ens19"
qm guest exec $nvm -- bash -c "sed -i '/^BOOTPROTO=/s/=.*/=static/' /etc/net/ifaces/ens19/options"
qm guest exec $nvm -- bash -c "touch /etc/net/ifaces/ens19/ipv4address"
qm guest exec $nvm -- bash -c "echo 172.16.1.5/30 > /etc/net/ifaces/ens19/ipv4address"
qm guest exec $nvm -- bash -c "cp -R /etc/net/ifaces/ens18 /etc/net/ifaces/ens20"
qm guest exec $nvm -- bash -c "sed -i '/^BOOTPROTO=/s/=.*/=static/' /etc/net/ifaces/ens20/options"
qm guest exec $nvm -- bash -c "touch /etc/net/ifaces/ens20/ipv4address"
qm guest exec $nvm -- bash -c "echo 172.16.0.1/24 > /etc/net/ifaces/ens20/ipv4address"
qm guest exec $nvm -- bash -c "cp -R /etc/net/ifaces/ens18 /etc/net/ifaces/ens21"
qm guest exec $nvm -- bash -c "sed -i '/^BOOTPROTO=/s/=.*/=static/' /etc/net/ifaces/ens21/options"
qm guest exec $nvm -- bash -c "touch /etc/net/ifaces/ens21/ipv4address"
qm guest exec $nvm -- bash -c "echo 172.16.1.1/24 > /etc/net/ifaces/ens21/ipv4address"
qm guest exec $nvm -- bash -c "sed -i '/^net.ipv4.ip_forward =/s/=.*/= 1/' /etc/net/sysctl.conf"
qm guest exec $nvm -- bash -c "iptables -t nat -A POSTROUTING -j MASQUERADE"
qm guest exec $nvm -- bash -c "iptables-save -f /etc/sysconfig/iptables"
qm guest exec $nvm -- bash -c "systemctl enable iptables"
qm guest exec $nvm -- bash -c "systemctl restart network"
qm guest exec $nvm5 -- bash -c "sed -i '/^BOOTPROTO=/s/=.*/=static/' /etc/net/ifaces/ens18/options"
qm guest exec $nvm5 -- bash -c "sed -i '/^NM_CONTROLLED=/s/=.*/=no/' /etc/net/ifaces/ens18/options"
qm guest exec $nvm5 -- bash -c "sed -i '/^DISABLED=/s/=.*/=no/' /etc/net/ifaces/ens18/options"
qm guest exec $nvm5 -- bash -c "echo 172.16.1.6/30 > /etc/net/ifaces/ens18/ipv4address"
qm guest exec $nvm5 -- bash -c "echo default\ via\ 172.16.1.5 > /etc/net/ifaces/ens18/ipv4route"
qm guest exec $nvm5 -- bash -c "echo nameserver\ 8.8.8.8 > /etc/net/ifaces/ens18/resolv.conf"
qm stop $nvm
qm stop $nvm5
echo "DONE!!!"
echo "Создание учетных записей"
{
pveum group add student-de --comment "users for DE"
pveum user add user$nvm@pve --password P@ssw0rd --enable 1 --groups student-de #Создание пользователей для доступа к стенду
pveum acl modify /vms/$nvm --roles PVEVMUser --users user$nvm@pve              #Выдача прав на доступ к стенду пользователям
pveum acl modify /vms/$nvm1 --roles PVEVMUser --users user$nvm@pve             #Выдача прав на доступ к стенду пользователям
pveum acl modify /vms/$nvm2 --roles PVEVMUser --users user$nvm@pve             #Выдача прав на доступ к стенду пользователям
pveum acl modify /vms/$nvm3 --roles PVEVMUser --users user$nvm@pve             #Выдача прав на доступ к стенду пользователям
pveum acl modify /vms/$nvm4 --roles PVEVMUser --users user$nvm@pve             #Выдача прав на доступ к стенду пользователям
pveum acl modify /vms/$nvm5 --roles PVEVMUser --users user$nvm@pve             #Выдача прав на доступ к стенду пользователям
}&>/dev/null
echo "Создание рабочего места $i завершено"
}

function deploy_stands { #функция указывающая сколько раз выполнить функцию настройки стенда

    for (( i=0; i < $nst; i++ ))
    do
        deploy_stand
    done
}
# Функция которую я не знаю как написать :-D
# function del_stand {
#     for((nvm=1000; nvm < 1100; nvm=$((nvm+10)))); do
    
#             for (( i=0;i<=5;i++ ))
#             do
#             nvi=$(($nvm + $i))
#                 qm destroy $nvi
#                 sed -i "/auto vmbr(($nvi))/,+6d" $path
#             done
#         echo "stand $i удален"
#     done

# }

clear
echo "+====== Сделай выбор ======+"
echo "|full deploy: 1            |"
echo "|download template: 2      |"
echo "|deploy from template: 3   |"
#echo "|del all stand 1000-1100: 4|"
echo "+--------------------------+"
read -p  "Выбор: " choice
read -p "Кол-во стендов на этой ноде: " nst

case $choice in
    1)
        download_template
        deploy_bridges_templates
        deploy_stands
        #run_stands
    ;;
    2)
        download_template
    ;;
    3) 
        deploy_bridges_templates
        deploy_stands
    ;;
    # 4)
    #     del_stand
    # ;;
    *)
        echo "Нереализуемый выбор"
        exit 1
    ;;
esac
#!/bin/bash

###中间菜单项暂不显示

read -p "请输入想要修改的主机名：" hostname
read -p "请输入想要修改的IP地址：" ip
#无用
hostnamectl set-hostname $hostname
echo "$ip $hostname" >> /etc/hosts

#安装依赖
yum install -y *epel* gcc-c++ unixODBC unixODBC-devel openssl-devel ncurses-devel
#安装erl环境
tar -xvf otp_src_27.0.tar.gz -C /usr/local
cd /usr/local/otp_src_27.0
./configure --prefix=/usr/local/erlang --enable-smp-support --enable-threads --enable-sctp --enable-kernel-poll --enable-hipe --with-ssl --without-javac
make && make install
echo "export PATH=$PATH:/usr/local/erlang/bin" >> /etc/profile
source /etc/profile

#安装rabbitmq
xz -d rabbitmq-server-generic-unix-3.13.2.tar.xz
tar -xvf rabbitmq-server-generic-unix-3.12.2.tar -C /usr/local
cd /usr/local/rabbitmq_server-3.7.0/sbin
echo "PATH=$PATH:/usr/local/rabbitmq/sbin"
source /etc/profile
rabbitmq-server -detached
#以下为创建用户
read -p "请输入想要创建的用户名：" username
read -p "请输入想要创建的用户密码：" password
rabbitmqctl add_user $username $password
rabbitmqctl set_user_tags $username administrator
rabbitmqctl set_permissions -p "/" $username ".*" ".*" ".*"

./rabbitmq-plugins enable rabbitmq_management

cd /etc/rabbitmq/
#修改配置文件
cp /usr/share/doc/rabbitmq-server-3.7.5/rabbitmq.config.example /etc/rabbitmq/rabbitmq.config
sed -i 's/#   {loopback_users, []},/  {loopback_users, false} /etc/rabbitmq/rabbitmq.config'
systemctl restart rabbitmq-server

mkdir -p /data/rabbitmq/{logs,data}
chmod -R 777 /data/rabbitmq
chown -R rabbitmq:rabbitmq /data/rabbitmq

curl $ip:15672


#部署集群
#cat >> /etc/rabbitmq/rabbitmq-env.conf <<EOF
#RABBITMQ_MNESIA_BASE=/data/rabbitmq/data
#RABBITMQ_LOG_BASE=/data/rabbitmq/logs
#EOF
#systemctl restart rabbitmq-server

#chmod 400 /var/lib/rabbitmq/.erlang.cookie
#chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
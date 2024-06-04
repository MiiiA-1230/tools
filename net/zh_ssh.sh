#!/bin/bash
#期待被zh_net.sh调用

ssh0 () {
  expect <<EOF
  spawn ssh-copy-id -i ~/.ssh/id_rsa.pub root@$1
  expect {
    "yes/no" { send "yes\r";exp_continue }
    "password:" { send "1\r" }
  }
EOF
  [ $? -eq 0 ] && addlog "远程主机ssh-keygen已配置" || addlog "远程主机ssh-keygen配置失败"
}

clear

which ssh-keygen > /dev/null
if [ $? -eq 0 ]; then
  echo "当前主机已生成ssh-keygen"
else
  echo "当前未生成ssh-keygen，正在生成配置"
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -q -N ""
  #生成ssh-keygen，密码为空
  addlog "ssh-keygen已生成"
fi

while ture
do
  read -p "请输入远程主机的IP地址（输入q退出）：  " ip_address
  [ $ip_address == "q" ] && break
  [[ !$ip_address =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && { echo "输入错误，请重新输入";continue;  }
  ssh0 "$ip_address" &
done
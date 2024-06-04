#!/bin/bash
#工具箱脚本草稿，暂不优化

ssh0 () {
  echo $1
  expect <<EOF
  spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$1
  expect {
    "*yes/no*" { send "yes\r";exp_continue }
    "*password*" { send "1\r" }
  }
  expect eof
EOF
}

clear

if [ -f /root/.ssh/id_rsa ];then
  echo "当前主机已生成ssh-keygen"
else
  echo "当前未生成ssh-keygen，正在生成配置"
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -q -N ""
  #生成ssh-keygen，密码为空
fi

for Ip_add in $(egrep "^server" work/hosts.ini | awk '{ print $2 }' | awk -F"=" '{ print $2 }');
do
    ssh0 "$Ip_add"
done

clear

ansible-playbook -i $tools_dir/net/hosts.ini $tools_dir/net/my_zabbix.yml
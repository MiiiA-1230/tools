#!/bin/bash
#期待被main.sh调用

clear
cat << EOF
  功能菜单：
  1  网关地址修改
  2  远程连接主机
  3  对主机进行批量安装zabbix-agent2

本机IP信息为：
EOF
ip=$(hostname -I)
#$(ip a | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n 1)
#查询本机IP，通过grep反转文本后由awk将ip赋给变量address，cut负责剪切及确定字段
echo $ip

read -p "你想要进行的操作是：" num

case $num in
1)
#设置新网关地址
#短，就不封装了，懒
#有需要时再做成函数
read -p "请输入新的网关地址" ip_new
route del default
route add default gw $ip_new
[ $? -eq 0 ] && addlog "网关修改成功" || addlog "网关修改失败"
;;
2)
bash $tools_dir/net/zh_ssh.sh
#进行ssh远程连接
;;
3)
bash $tools_dir/net/zh_install_zabbix_agent2.sh
;;
*)
echo "Bye~"
;;
esac

echo "即将退回主界面..."
sleep 1

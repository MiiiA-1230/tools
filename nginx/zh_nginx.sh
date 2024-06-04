#!/bin/bash
#期待被main.sh调用
#格式同zh_httpd一样，后期考虑重新封装

clear

which niginx > /dev/null
if [ $? == 0 ]; then
  echo "当前已安装nginx服务"
else
  echo "当前未安装nginx服务，请退回主菜单先进行安装"
  sleep 1
  exit
fi

echo "正在检测Nginx用户信息："
groups nginx
cat <<EOF
————————————————————————————————
| 请确认信息,否则后续无法正常使用 |
| 1  继续操作                   |
| 2  我要退出                   |
————————————————————————————————
EOF
read num

[ $num -eq 2 ] && { echo "正在退出中...";sleep 1;exit; } || echo "正在关闭防火墙"
systemctl stop firewalld
setenforce 0

echo "正在检测nginx服务状态..."
systemctl status nginx > /dev/null
if [ $? -eq 3 -o $? -eq 1 ];then
  #执行1
  echo "nginx服务未开启，正在开启中..."
  systemctl start nginx > /dev/null
elif [ $? -eq 0 ];then
  #执行2
  echo "nginx服务已开启，正在配置环境..."
else
  #执行3
  echo "[ERROR] NGINX服务状态未知，请联系管理员"
  exit
fi
#$?=4未接触，处理方式不了解，暂定跳过

cat <<EOF
你想要进行的操作是：
1  创建网站模板
2  创建web负载均衡器
EOF
read num

ip_address=$(hostname -I)
nginx_port=$(grep -E '^listen ' /etc/nginx/nginx.conf | cut -d ' ' -f2)
#查询本机IP，通过grep反转文本后由awk将ip赋给变量address，cut负责剪切及确定字段


case $num in
1)
read -p "请输入你想创建的网站名称" server_dir
server_dir="$tools_dir/nginx/$server_dir"

if [ -f $server_dir ];then
  echo "[ERROR 301] 文件创建时受阻碍，请联系管理员解决"
  read -p "输入任意字符可回退至主菜单" status
  exit 0
else
  read -p "请输入你想创建的网站域名，请勿与已有网站冲突" web_address
  mkdir -p "$server_dir"
  addlog "$server_dir网站目录server_dir已创建"
  #将创建网站目录的操作记录在案

cat > /etc/nginx/conf.d/zh_test.conf <<EOF
server {
listen $httpd_port;;
server_name $ip_address;
  location / {
    root $server_dir;
    index index.html;
  }
}
EOF

[ !$(nginx -t) ] && {
  echo "配置文件有误，请检查"
  sleep 1
  exit
}
#检查配置文件是否正确

addlog "/etc/nginx/conf.d/zh_test.conf文件信息已追加"
  echo "测试页面" > $server_dir/index.html
  addlog "测试页面已创建"

  echo "$ip_address:$httpd_port    $web_address   $server_dir   可供清理;" >> /etc/hosts
  #/etc/hosts的清理问题，考虑添加不存在的信息做区分
  addlog "/etc/hosts文件信息已追加,本次操作已结束"
  systemctl restartnginx.service &
  #重启httpd服务

  curl $ip_address:$httpd_port
  #无法解析域名，因为没有配置DNS，只尝试了用域名端口做区分的方法
  #懒得写端口相关了，就这样吧

fi
;;
#创建网站模板功能完毕
2)cat <<EOF
负载均衡器类型：
a  轮询
b  权重
EOF
read num

read -p "请输入负载均衡器名称" lb_name
#lb_name意为负载均衡器名称

read -p "请输入负载均衡器IP地址" ip_address0
read -p "请输入负载均衡器端口号" httpd_port0

read -p "请输入第一个服务器IP地址" ip_address1
read -p "请输入第二个服务器IP地址" ip_address2

read -p "请输入第一个服务器的端口号" httpd_port1
read -p "请输入第二个服务器的端口号" httpd_port2

case $num in
a)
cat > /etc/nginx/conf.d/zh_test.conf <<EOF
upstream $lb_name {
  server $ip_address1:$httpd_port1;
  server $ip_address2:$httpd_port2;
}

server {
  listen $httpd_port0;
  server_name $ip_address0;
  location / {
    proxy_pass http://$lb_name;
  }
}
EOF
;;
#创建轮询模式完毕
b)
#read -p "请输入第一个服务器的权重" weight1
#read -p "请输入第二个服务器的权重" weight2
#具体权重
cat>> /etc/nginx/conf.d/zh_test.conf <<EOF
upstream $lb_name {
  server $ip_address1:$httpd_port1 weight=1;
  server $ip_address2:$httpd_port2 weight=2;
}
server {
  listen $httpd_port0;
  server_name $ip_address0;
  location / {
    proxy_pass http://$lb_name;
  }
}
EOF
;
#创建权重模式完毕
esac
#负载均衡器类型选择完毕
;;
#创建web负载均衡器功能完毕
*)
;;
esac
#!/bin/bash
#期待被main.sh调用

clear

which httpd > /dev/null
if [ $? == 0 ]; then
  echo "当前已安装httpd服务"
else
  echo "当前未安装httpd服务，请退回主菜单先进行安装"
  sleep 1
  exit
  #[[ "$num" == "y" || "$num" == "Y" ]] && source $tools_dir/yum.
  #原本考虑调用函数，考虑因需要x权限损失安全性，取消。（主要是懒了）
fi

echo "正在检测Apache用户信息："
groups apache
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

echo "正在检测httpd服务状态..."
systemctl status httpd > /dev/null
if [ $? -eq 3 ];then
  #执行1
  echo "httpd服务未开启，正在开启中..."
  systemctl start httpd > /dev/null
elif [ $? -eq 0 ];then
  #执行2
  echo "httpd服务已开启，正在配置环境..."
else
  #执行3
  echo "[ERROR] HTTPD服务状态未知，请联系管理员"
  exit
fi

cat <<EOF
你想要进行的操作是：
1  创建网站模板
2  待定
EOF
read num

################################################################################################
ip_address=$(ip a | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n 1)
#查询本机IP，通过grep反转文本后由awk将ip赋给变量address，cut负责剪切及确定字段
httpd_port=$(grep -E '^Listen ' /etc/httpd/conf/httpd.conf | cut -d ' ' -f2)
#查询本机httpd端口，通过grep检索httpd.conf，并通过cut进行字段剪切
#
#echo "测试先到这里"
#exit 0 
################################################################################################

case $num in
1)
read -p "请输入你想创建的网站名称" server_dir
server_dir="$tools_dir/httpd/$server_dir"

if [ -f $server_dir ];then
  echo "[ERROR 301] 文件创建时受阻碍，请联系管理员解决"
  read -p "输入任意字符可回退至主菜单" status
  exit 0
else
  read -p "请输入你想创建的网站域名，请勿与已有网站冲突" web_address
  mkdir -p "$server_dir"
  addlog "$server_dir网站目录server_dir已创建"
  #将创建网站目录的操作记录在案

cat >> /etc/httpd/conf.d/zh_test.conf <<EOF
<VirtualHost $ip_address:$httpd_port>
DocumentRoot $server_dir"
ServerName $web_address"
<Directory "$server_dir/">
AllowOverride None
Require all granted
</Directory>
</VirtualHost>

EOF
  addlog "/etc/httpd/conf.d/zh_test.conf文件信息已追加"
  echo "测试页面" > $server_dir/index.html
  addlog "测试页面已创建"

  echo "$ip_address:$httpd_port    $web_address   $server_dir   可供清理" >> /etc/hosts
  #/etc/hosts的清理问题，考虑添加不存在的信息做区分
  addlog "/etc/hosts文件信息已追加,本次操作已结束"
  systemctl restart httpd.service &
  #重启httpd服务

  curl $ip_address:$httpd_port
  #无法解析域名，因为没有配置DNS，只尝试了用域名端口做区分的方法
  #懒得写端口相关了，就这样吧

fi
;;
2)
;;
*)
;;
esac
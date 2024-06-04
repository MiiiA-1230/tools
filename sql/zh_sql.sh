#!/bin/bash
#期待被main.sh调用
#默认SSH连接已配置，账号为root，密码为1
#考虑代码优化

sql_0(){
  mysql -uroot -p1 -e "$1"
}
sql_1(){
  local ip=$1
  local command=$2
  mysql -uroot -p1 -h$ip -e "$command"
}

cat <<EOF
请选择你的操作：
1 单库备份
2 远程单库备份
3 全库备份
4 主从机配置
5
EOF
read num


case $num in 
1)
  dbnames=($(mysql -u root -p1 -e 'show databases;' | tail -n +2))

  n=1
  for db_name in "${dbnames[@]}"
  do
    if [[ $db_name == "information_schema" || $db_name == "sys" || $db_name == "mysql" || $db_name == "performance_schema" ]];then  continue; fi
    dbnames2+=("$db_name")
    echo "$n:$db_name"
    n=$(($n+1))
  done

  read -p "你想备份的数据库为：" num2
  mysqldump -u root -p1 ${dbnames[num2]} > $tools_log_dir/sql/${dbnames2[num2-1]}_$(date +%Y-%m-%d_%H-%M-%S).sql
;;
#本地库备份完成
2)
  read -p "你要远程连接的服务器ip是：" ip
  dbnames=($(mysql -u root -p1 -h $ip -e 'show databases;' | tail -n +2))

  n=1
  for db_name in "${dbnames[@]}"
  do
    if [[ $db_name == "information_schema" || $db_name == "sys" || $db_name == "mysql" || $db_name == "performance_schema" ]];then  continue; fi
    dbnames2+=("$db_name")
    echo "$n:$db_name"
    n=$(($n+1))
  done

  read -p "你想备份的数据库为：" num2
  mysqldump -u root -p1 -h$ip ${dbnames[num2]} > $tools_log_dir/sql/${dbnames2[num2-1]}_$(date +%Y-%m-%d_%H-%M-%S).sql
;;
#远程备份完成
3)
cat << EOF
你要备份的是：
1 本地数据库
2 远程数据库

EOF

read num3
if [ $num3 -eq 1 ];then
	mysqldump -u root -p1 -A > $tools_log_dir/sql/all_$(date +%Y-%m-%d_%H-%M-%S).sql
elif [ $num3 -eq 2 ];then
	read -p "你要远程连接的服务器ip是：" ip
	mysqldump -u root -p1 -h$ip > $tools_log_dir/sql/all_$ip_$(date +%Y-%m-%d_%H-%M-%S).sql
else
	echo "别捣乱"
	sleep 1
fi
;;
#全库备份完成
4)
echo "正在进行主机配置..."
#主机配置开始
sed -i '/^server-id/d' /etc/my.cnf
sed -i '/^log-bin/d' /etc/my.cnf
cat >> /etc/my.cnf <<EOF
log-bin=/var/log/mysql/mysql-bin
server-id=1
EOF
[[ -d /var/log/mysql ]] || mkdir /var/log/mysql; 
chown mysql.mysql /var/log/mysql
systemctl restart mysqld
#主机配置完成
echo "主机配置完成"

file_name=$(sql_0 "SHOW MASTER STATUS\G" | grep -E File | awk -F' ' '{print $2}')
#echo $file_name
position_id=$(sql_0 "SHOW MASTER STATUS\G" | grep -E Position | awk -F' ' '{print $2}')
#echo $position_id

##开始SSH连接从机,默认已配置完毕，使用root账号，密码为1
read -p "请输入你想配置的从机的IP地址:" slave_ip
read -p "请输入你想配置的从机的server-id:" slave_id

master_ip=$(hostname -I | awk '{print $1}')

echo "开始进行从机配置..."

ssh root@$slave_ip <<EOF
sed -i '/^server-id/d' /etc/my.cnf
echo "server-id=$slave_id" >> /etc/my.cnf
systemctl restart mysqld &
exit
EOF

sql_1 "$slave_ip" "stop slave;"
sql_1 "$slave_ip" "
CHANGE MASTER TO 
MASTER_HOST='$master_ip',
MASTER_USER='root',
MASTER_PASSWORD='1',
MASTER_LOG_FILE='$file_name',
MASTER_LOG_POS=$position_id;"

sql_1 "$slave_ip" "start slave;"
sql_1 "$slave_ip" "show slave status\G"

echo "$slave_ip 从机配置完成"

;;
#主从机配置完毕
5)
;;
*)
echo "别捣蛋"
sleep 1
;;
esac

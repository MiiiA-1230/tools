#!/bin/bash
#个人脚本，考虑优化程序结构来完成所有功能

export tools_dir=$(cd $(dirname $0);pwd)
function addlog(){
echo "正在写入操作日志"
cat >> $log_dir/Operation_Logs.log <<EOF
$(date +%F)
$1
over

EOF
echo "写入日志成功"
}
export -f addlog

###环境变量设置

clear

while :
do
#以下是目录内文件内容的功能（一一对应）
cat << EOF
  你要进行的操作是：
  1  网络操作
  2  用户操作
  3  HTTPD服务
  4  NGINX服务
  5  软件安装
  6  软件卸载
  7  数据库备份
  0  结束程序
EOF

read num

case $num in
1)
bash $tools_dir/net/zh_net.sh
;;
2)
bash $tools_dir/user/zh_user.sh
;;
3)
bash $tools_dir/httpd/zh_httpd.sh
;;
4)
bash $tools_dir/nginx/zh_nginx.sh
;;
5)
bash $tools_dir/yum/zh_yum.sh
;;
6)
bash $tools_dir/remove/zh_remove.sh
;;
7)
bash $tools_dir/sql/zh_sql.sh
;;
0)
echo "即将结束程序"
exit
;;
*)
echo "输入有误，请重新输入"
;;
esac

done
sleep 1
echo "感谢使用，再见"

#!/bin/bash
#期待被主文件main.sh调用
#试验中，卸载功能，由课堂作业变化而来

#yum list installed
#查看已安装软件

cat <<EOF
—————————————————————————
|  你想卸载什么软件？     |
|  1  卸载httpd服务      |
|  2  卸载nginx服务      |
|  3  卸载mysql服务      |
|  4  待定              |
|  0  退回主界面         |
——————————————————————————
EOF
read num

case $num in
1)
;;
2)
;;
3)
;;
4)
;;
*)
;;
esac
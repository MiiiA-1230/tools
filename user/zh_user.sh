#!/bin/bash
#期待被main.sh调用

clear
cat <<EOF
你正在进行用户操作
目前存在的普通用户情况为：
EOF

awk -F":" '$3 == 0 || $3 >= 1000 { print $1 ":" $3 }' /etc/passwd
#只列出root和普通用户列表 cat /etc/passwd

cat <<EOF
  目前可提供的功能有：
  1  创建用户
  2  删除用户
EOF

read -p "你想要进行的操作是：" num

case $num in 
1)
  read -p "请输入你想创建的用户名称：" user_name
  id $user_name &> /dev/null
  if [ $? -eq 0 ]
  then
    addlog "创建用户失败，用户已存在"
  else
    useradd $user_name &> /dev/null
    addlog "成功创建用户"
    id $user_name
  fi
;;
2)
  read -p "请输入你想删除的用户名称：" user_name
  id $user_name &> /dev/null
  if [ $? -eq 0 ]
  then
    userdel -r $user_name
    addlog "删除成功"
  else
    addlog "不存在该用户，无法删除"
  fi
;;
*)
  echo "输入错误，正在退回主菜单"
;;
esac

sleep 1
echo "Bye bye~"

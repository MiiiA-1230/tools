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
  3  创建高级权限用户
  4  对高级权限用户进行降权
EOF

read -p "你想要进行的操作是：" Num

case $Num in 
  1)
    read -p "请输入你想创建的用户名称：" User_Name
    read -p "请输入你想创建的用户密码：" User_Password
    id $User_Name &> /dev/null
    if [ $? -eq 0 ]
    then
      addlog "创建用户失败，用户已存在"
    else
      useradd $User_Name &> /dev/null
      echo $User_Password | passwd --stdin $User_Name
      addlog "成功创建用户"
      id $User_Name
    fi
  ;;
  2)
    read -p "请输入你想删除的用户名称：" User_Name
    id $User_Name &> /dev/null
    if [ $? -eq 0 ]
    then
      userdel -r $User_Name
      addlog "删除成功"
    else
      addlog "不存在该用户，无法删除"
    fi
  ;;
  3)
    read -p "请输入你想创建的用户名称：" User_Name
    read -p "请输入你想创建的用户密码：" User_Password
    id $User_Name &> /dev/null
    if [ $? -eq 0 ]
    then
      addlog "创建用户失败，用户已存在"
    else
      useradd $User_Name &> /dev/null
      echo $User_Password | passwd --stdin $User_Name
      echo "$User_Name ALL=(ALL) ALL" >> /etc/sudoers
      addlog "成功创建高级权限用户"
      id $User_Name
    fi
  ;;
  4)
    read -p "请输入你想降权的用户名称：" User_Name
    id $User_Name &> /dev/null
    cp /etc/sudoers /etc/sudoers.bak
    sed -i "/^$User_Name ALL=(ALL) ALL/d" /etc/sudoers
  ;;
  *)
    echo "输入错误，正在退回主菜单"
  ;;
esac

sleep 1
echo "Bye bye~"
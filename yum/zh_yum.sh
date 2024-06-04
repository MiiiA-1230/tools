#!/bin/bash
#期待被main.sh调用

test_yum() {
  yum check-update &> /dev/null

  if [ $? -ne 0 ] && [ $? -ne 100 ];then
	echo "当前YUM存在问题，正在处理"
	
	yum clean all
	rm -rf /var/cache/yum
	yum update
  else
	echo "YUM自检完毕,即将进入主菜单"
	sleep 1
	return 10
  fi
}


clear
read -p "是否进行yum自检?(确认请输入0)" num
[ $num -eq 0 ] && test_yum 

date >> $tools_dir/operation_logs.log

tools_dir=$(cd $(dirname $0);pwd)

echo "你想安装的服务是："

echo "####################"
echo "#你想安装的服务是：#"
echo "#1 httpd           #"
echo "#2 nginx           #"
echo "#3 nfs及rpcbind    #"
echo "#4 vsftpd          #"
echo "#5 mysql           #"
echo "#9 基础环境配置    #"
echo "#0 退回上级菜单    #"
echo "####################"
read num 

case $num in 
1)
	which httpd
	if [ $? -eq 0 ]
	then
		echo "已安装httpd"
		exit 0

	else
		echo "开始安装httpd服务..."
		addlog "安装httpd服务"
		#记录安装httpd服务
		yum -y install httpd
	fi
#if判断结束
;;
#一级case判断一号选(安装httpd)项结束
2)
	which nginx

	if [ $? -eq nginx ]
	then
		echo "已安装nginx"
		exit 0

	else
		echo "开始安装nginx服务..."
		
		addlog "安装nginx服务"

		echo "安装nginx的方式为："
		echo "1 编译安装"
		echo "2 yum安装"
		read num
		
		#二级case判断开始		
		case $num in
		1)
			addlog "编译安装nginx服务"

			#编译安装
			yum -y install gcc make zlib-devel pcre pcre-devel openssl-devel
			#准备编译环境
			wget http://nginx.org/download/nginx-1.24.0.tar.gz
			tar xzf nginx-1.24.0.tar.gz
			cd nginx-1.24.0
			#解压
	
			./configure --user=www --group=www --prefix=/usr/local/nginx
			make
			make install
			#编译及安装
	
			useradd www
			#创建nginx用户
			;;
			#分割线——————————————————————————————————————————————
		
		2)
			addlog "yum安装nginx服务"
			
			#yum安装
			cd /etc/yum.repos.d/
			vim nginx.repo
			echo "[nginx]"
			echo "name=nginx"
			echo "baseurl=http://nginx.org/packages/centos/$releasever/$basearch/"
			echo "gpgcheck=0"
			echo "enabled=1"
		
			yum clean all
			yum makecache
			yum install -y nginx
			;;
		
			#分割线——————————————————————————————————————————————
			*)
			echo "输入错误"
			;;
		esac
		#二级case判断结束
	fi
	#if判断结束
;;
#一级case判断二号选项(安装nginx)结束
3)
	yum list | grep nfs-utils

	if [ $? -eq 0 ]
	then
		#已安装nfs-utils
		echo "nfs-utils服务已安装"
		exit 0
	else
		#未安装nfs-utils
		
		echo "开始安装nfs-utils及rpcbind服务..."
		addlog "安装nfs-untls服务"
		yum -y install nfs-utils
		addlog "安装rpcbind服务"
		yum -y install rpcbind
	fi 
sleep 1
;;
#一级case判断三号选项(安装nfs及rpcbind)结束
4)
which vsftpd
if [ $? -eq 0 ];then
  echo "已安装vsftpd服务"
else
  echo "即将开始安装vsftpd服务"
  yum install -y vsftpd
  if [ $? -eq 0 ];then
	echo "安装vsftpd服务成功"
	addlog "安装vsftpd成功"
  else
	echo "安装vsftpd服务失败，请联系管理员处理"
	addlog "安装vsftpd失败"
  fi
fi
sleep 1
;;
#一级case判断四号选项(vsftp)结束
5)
/usr/local/mysql/bin/mysql -version &> /dev/null
[ &? -eq 0 ] && { echo "mysql文件已存在"; addlog "mysql已存在"; exit; } || echo "mysql文件不存在"
cat << EOF
选择你的安装方式：
1 YUM安装
2 编译安装
EOF
read num
if [ $num -eq 1 ] ;then { yum -install -y mysql; addlog "YUM安装MYSQL成功"; exit; } fi
if [ $num -eq 2 ] ;then
  wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-boost-5.7.27.tar.gz
  yum -y install ncurses ncurses-devel openssl-devel bison gcc gcc-c++ make
  yum -y install cmake
  mkdir -p /usr/local/{data,mysql,log}
  tar xzvf mysql-boost-5.7.27.tar.gz -C /usr/local/
  cd /usr/local/mysql-5.7.27/
#开始设置环境##############################################
  cmake . \
-DWITH_BOOST=boost/boost_1_59_0/ \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DSYSCONFDIR=/etc \
-DMYSQL_DATADIR=/usr/local/mysql/data \
-DINSTALL_MANDIR=/usr/share/man \
-DMYSQL_TCP_PORT=3306 \
-DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
-DDEFAULT_CHARSET=utf8 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_READLINE=1 \
-DWITH_SSL=system \
-DWITH_EMBEDDED_SERVER=1 \
-DENABLED_LOCAL_INFILE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1

#结束设置环境##############################################
  make && make install
  cd /usr/local/mysql
  chown -R mysql.mysql .
  ./bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data | awk -RS":" 'END{print "$(date +%F: )"$NR}' >> /usr/local/mysql_$(date +%F).passwd
  cat>/etc/my.cnf<<EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/usr/local/mysql/data
EOF
#安装完毕#################################################
  echo "MYSQL安装完毕"
  addlog "编译安装MYSQL成功"
else
  echo "ERROR502 请联系管理员解决"
  addlog "MYSQL编译安装失败"
fi
sleep 1
;;
#一级case判断五号选项(mysql)结束
9)
test_yum
if [ $? -eq 10 ];then
echo "不知道要干嘛"
#没想好要装啥
else
  echo "yum服务出错，请联系管理员处理"
  addlog "ERROR901 yum服务出错，请联系管理员处理"
fi
sleep 1
;;
#一级case判断号选项(基础环境配置)结束
0)
echo "好的，请稍等"
sleep 1
exit 0
;;

*)
echo "请输入正确的选项"
sleep 1
exit 0
;;

esac

1、zabbix_agent2的批量安装功能的实现需要hosts.ini、my_zabbix.yml、zh_install_zabbix_agent2.sh三个文件实现功能的运行
    1.1、hosts.ini文件：记录主从机IP信息及分组
    1.2、my_zabbix.yml文件：预先配置好的zabbix安装时应用的剧本运行代码
    1.3、zh_install_zabbix_agent2.sh文件：实现zabbix_agent2的批量安装及配置的功能
2、该net文件夹中zh_net.sh文件为二级菜单，主要功能有：
    1、网关地址修改
    2、使用zh_ssh.sh文件实现远程连接主机
    3、使用zh_install_zabbix_agent2.sh文件实现远程批量安装zabbix_agent2

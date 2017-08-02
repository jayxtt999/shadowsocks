#!/bin/bash
clear;
## 检查 root 权限
[ $(id -g) != "0" ] && die "Script must be run as root.";
DISTRO='';
ipAddress=`ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\." | head -n 1`;
password=`echo -n $RANDOM  | md5sum | sed "s/ .*//" | cut -b -8`;
configPath='/etc/shadowsocks/';
config='config.json';
port=444


Check_Py_Version()
{
	pyversion = `python -V 2>&1|awk '{print $2}'|awk -F '.' '{print $1$2}'` 
	if ["$pyversion" < 27 ]; then
	
		read -p '[Notice] your python version < 2.7,install? : (y/n)' confiInPy;
		if [ "$confiInPy" == 'y' ]; then
			wget https://www.python.org/ftp/python/2.7.12/Python-2.7.12.tgz
			tar -zxvf Python-2.7.12.tgz;
			cd Python-2.7.12;
			./configure --prefix=/usr/local/python27;
			make && make install
		fi;	
	fi
	
	
}

Get_Dist_Name()
{
    if grep -Eqii "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
		Check_Py_Version
		yum install -y python-setuptools && easy_install pip
		pip install shadowsocks
    elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
        DISTRO='RHEL'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
        DISTRO='Aliyun'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        DISTRO='Fedora'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
		apt-get install -y python-pip
		pip install shadowsocks
    elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
        DISTRO='Raspbian'
    else
        DISTRO='unknow'
    fi
}

Check_Port()
{
	pIDa=`netstat -nlp | grep :${port} | awk '{print $7}' | awk -F"/" '{ print $1 }'`
	if [ "$pIDa" != "" ]; then
		read -p '[Notice] port:'$port' address already in use bind, kill ? : (y/n)' confirmKill;
		if [ "$confirmKill" == 'n' ]; then
			echo "bye~~";
			exit;
		elif [ "$confirmDM" != 'y' ]; then
			kill -9 $(netstat -nlp | grep :${port} | awk '{print $7}' | awk -F"/" '{ print $1 }') ;
		fi;
	fi	
}


Input_IP()
{
    if [ "$ipAddress" == '' ]; then
        echo '[Error] Empty server ip.';
        read -p '[Notice] Please input server ip:' ipAddress;
		if [ "$ipAddress" == '' ]; then
			Input_IP;
		fi;
    else
        echo '[OK] Your server ip is:' && echo $ipAddress;
        read -p '[Notice] This is your server ip? : (y/n)' confirmDM;
		if [ "$confirmDM" == 'n' ]; then
			ipAddress='';
			Input_IP;
		elif [ "$confirmDM" != 'y' ]; then
			Input_IP;
		fi;
    fi;
}

Get_Dist_Name
Check_Port
Input_IP
rm -rf $configPath;
mkdir  $configPath;
touch $configPath/$config;
echo "{" >> $configPath/$config;
echo "\"server\":\"${ipAddress}\"," >> $configPath/$config;
echo "\"server_port\":${port}," >> $configPath/$config;
echo "\"local_port\":1080," >> $configPath/$config;
echo "\"password\":\"${password}\"," >> $configPath/$config;
echo "\"method\":\"aes-256-cfb\"" >> $configPath/$config;
echo "}" >> $configPath/$config;

nohup ssserver -c $configPath/$config >> /dev/null 2>&1 & 

echo -e "\033[34m shadowsocks config: \033[0m ${configPath}${config}";
echo -e "\033[34m shadowsocks server: \033[0m ${ipAddress}";
echo -e "\033[34m shadowsocks port: \033[0m ${port}";
echo -e "\033[34m shadowsocks local_port: \033[0m 1080";
echo -e "\033[34m shadowsocks Password: \033[0m ${password}";
echo -e "\033[34m shadowsocks method: \033[0m aes-256-cfb";



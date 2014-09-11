#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must get root privilege at first."
    exit 1
fi

clear
echo ""
echo -e "\033[7m"
echo "+---------------------------------------------------------------------+"    
echo "+                                                                     +"    
echo "+  Logstash-index + Elasticsearch + BIGLog                            +"
echo "+                                                                     +"    
echo "+          Power by: www.biglog.org (craazw@gmail.com)                +"    
echo "+                                                                     +"    
echo "+---------------------------------------------------------------------+"    
echo -e "\033[0m"
echo

function InitInstall()
{
echo "======================InitInstall======================"
cat /etc/issue
uname -a
MemTotal=`free -m | grep Mem | awk '{print  $2}'`  
echo -e "\n Memory is: ${MemTotal} MB "
#Set timezone
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

yum install -y ntp
ntpdate -u pool.ntp.org
date

#Resolve dependencies

#Disable SeLinux
# if [ -s /etc/selinux/config ]; then
# sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
# fi

for packages in patch make cmake gcc gcc-c++ gcc-g77 flex bison file libtool libtool-libs autoconf kernel-devel libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel bzip2 bzip2-devel libevent libevent-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel vim-minimal nano fonts-chinese gettext gettext-devel ncurses-devel gmp-devel pspell-devel unzip libcap;
do yum -y install $packages; done

for packages in git java-1.7.0-openjdk java-1.7.0-openjdk-devel openssl-devel zlib-devel zlib;
do yum -y install $packages; done

cat>> /etc/security/limits.conf <<EOF
* soft unlimited
* soft nofile 65535
* hard nofile 65535
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
elasticsearch soft rss unlimited
elasticsearch hard rss unlimited
elasticsearch soft stack unlimited
elasticsearch hard stack unlimited
elasticsearch soft nofile 256000
elasticsearch hard nofile 256000
EOF
echo "======================InitInstall Completed======================"
}

function InstallSingleLogstash()
{
echo "=============================Install  Logstash-Index================================"
#install logstash
cd /home
wget -O /home/logstash-1.4.2.tar.gz http://update.biglog.org/logstash-1.4.2.tar.gz
tar zxvf logstash-1.4.2.tar.gz
rm -rf logstash-1.4.2.tar.gz
mv logstash-1.4.2 logstash
mkdir /etc/logstash
mkdir /var/log/logstash

#touch index.conf
cat >> /etc/logstash/index.conf<<EOF
input {
	syslog {
		type => "syslog"
		port => 514
		codec => plain {
		charset => "GBK"
		}
	}
	}

output {
  elasticsearch {
  host => "127.0.0.1"  }   
}
EOF

#Add grep plugins
cd /home/logstash
bin/plugin install contrib

#Add chkconfig
wget -O /etc/init.d/logstash http://update.biglog.org/logstash
chmod +x /etc/init.d/logstash
chkconfig --add logstash
chkconfig logstash on
service logstash start

echo "======================-====Logstash-index install completed========================="
}

function InstallSingleElasticsearch()
{
echo "==============================Install Single Elasticsearch================================="
#download 
cd /tmp
wget http://update.biglog.org/elasticsearch-1.3.0.tar.gz
tar zxvf elasticsearch-1.3.0.tar.gz
mv elasticsearch-1.3.0 /home/elasticsearch
rm -rf *.gz

#copy service
cd /tmp
git clone https://github.com/elasticsearch/elasticsearch-servicewrapper.git
cd /tmp/elasticsearch-servicewrapper
mv service /home/elasticsearch/bin/
cd /tmp
rm -rf elasticsearch-servicewrapper
cd /home/elasticsearch/bin/service
memtotal=`cat /proc/meminfo | grep "MemTotal" | awk '{print $2}'`
setmem=$(($memtotal*6/10240))
sed -i '1s|.*|set.default.ES_HOME=/home/elasticsearch|' /home/elasticsearch/bin/service/elasticsearch.conf
sed -i "2s|.*|set.default.ES_HEAP_SIZE=${setmem}|" /home/elasticsearch/bin/service/elasticsearch.conf

./elasticsearch install

#start the service
service elasticsearch start

#install the management tool of elasticsearch
cd /home/elasticsearch/
bin/plugin -install mobz/elasticsearch-head
bin/plugin -install lmenezes/elasticsearch-kopf

wget -O /home/elasticsearch/plugin/sense.tar.gz http://update.biglog.org/sense.tar.gz
tar zxvf sense.tar.gz
rm -rf /home/elasticsearch/plugin/sense.tar.gz

echo "=========================Single Elasticsearch Install Completed====================="
}

function InstallKibana()
{
echo "==================================Install BIGLog_kibana ============================="
mkdir /home/wwwroot
cd /home/wwwroot
wget http://update.biglog.org/biglog.tar.gz
tar zxvf biglog.tar.gz
rm -f biglog.tar.gz
rm -rf /tmp/biglog_standalone.sh /tmp/nginx-1.4.5 /tmp/pcre-8.10
echo "=============================BIGLog Install Completed========================="
}

function InstallNginx()
{
echo "==================================Install Nginx ============================="
#install
cd /tmp
wget http://nginx.org/download/nginx-1.4.5.tar.gz
wget http://update.biglog.org/pcre-8.10.tar.gz
tar zxvf nginx-1.4.5.tar.gz
tar zxvf pcre-8.10.tar.gz
groupadd www
useradd -g www -s /bin/false -M www
mkdir /usr/local/nginx
cd /tmp/nginx-1.4.5
./configure --user=www --group=www --prefix=/usr/local/nginx  --with-pcre=../pcre-8.10 --with-http_stub_status_module --with-http_gzip_static_module --without-mail_pop3_module --without-mail_smtp_module --without-mail_imap_module --without-http_uwsgi_module --without-http_scgi_module
make && make install

#Add vhost
sed -i "44s|.*|             root   /home/wwwroot/biglog;|" /usr/local/nginx/conf/nginx.conf

#add chkconfig file
wget -O /etc/init.d/nginx http://update.biglog.org/nginx
chmod u+x /etc/init.d/nginx
chkconfig --add nginx
chkconfig --level 345 nginx on

/etc/init.d/nginx restart

echo "=============================Nginx Install Completed========================="
}


#BIGLog Stand-alone Install?
echo "==========================="

  echo "Install BIGLog Stand-alone, Please Input y"
  read -p "(Please input y or n):" isinstallbiglog

  case "$isinstallbiglog" in
  y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
  echo "You will install BIGLog Stand-alone"
  isinstallbiglog="y"
  ;;
  *)
  echo "INPUT error,Please run the shell again!"
  exit 1
  esac

if [ "$isinstallbiglog" = "y" ]; then
  #do you want to install the nginx?
  echo "==========================="

  installnginx="n"
  echo "Do you want to install the Nginx for BIGLog Webmanage?"
  read -p "(Default no,if you want press: y; if not, press: n):" installnginx

  case "$installnginx" in
  y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
  echo "You will install the Nginx!"
  installnginx="y"
  ;;
  n|N|No|NO|no|nO)
  echo "You will NOT install the Nginx!"
  installnginx="n"
  ;;
  *)
  echo "INPUT error,The Nginx will NOT install!"
  installnginx="n"
  esac

  InitInstall
  if [ "$installnginx" == "y" ]; then
    InstallNginx
  fi  
  InstallSingleLogstash
  InstallSingleElasticsearch
  InstallKibana
fi

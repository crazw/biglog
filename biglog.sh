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
echo "+  Awesant + Logstash-index + Elasticsearch( master/node ) +  Kibana  +"    
echo "+                                                                     +"    
echo "+          Power by: www.biglog.org (zooboa@gmail.com)                +"    
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

# cp /etc/yum.conf /etc/yum.conf.lnmp
# sed -i 's:exclude=.*:exclude=:g' /etc/yum.conf

for packages in patch make cmake gcc gcc-c++ gcc-g77 flex bison file libtool libtool-libs autoconf kernel-devel libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel bzip2 bzip2-devel libevent libevent-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel vim-minimal nano fonts-chinese gettext gettext-devel ncurses-devel gmp-devel pspell-devel unzip libcap;
do yum -y install $packages; done

for packages in git java-1.7.0-openjdk java-1.7.0-openjdk-devel openssl-devel zlib-devel zlib;
do yum -y install $packages; done

# mv -f /etc/yum.conf.lnmp /etc/yum.conf
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
echo "======================InitInstall completed======================"
}


function InstallAwesant()
{
echo "======================Install  Awesant Log Shipper Agent======================"
# add source
cat >> /etc/yum.repos.d/awesant.repo <<EOF
[awesant]
name=awesant
baseurl=https://download.bloonix.de/centos/\$releasever/\$basearch
gpgcheck=0
EOF

#install GPG Key
wget https://download.bloonix.de/centos/RPM-GPG-KEY-Bloonix
rpm --import RPM-GPG-KEY-Bloonix
mv RPM-GPG-KEY-Bloonix /etc/pki/rpm-gpg/

#install awesant
yum -y install awesant

#write the agent.conf file
#------------------还没有测通----------------------------------------


#add chkconfig
chkconfig --add awesant-agent
chkconfig awesant-agent on
service awesant-agent start

echo "============================Awesant install completed========================="
}

function InstallSingleLogstash()
{
echo "=============================Install  Logstash-index================================"
#install logstash
cd /home
wget -O /home/logstash-1.4.0.tar.gz https://download.elasticsearch.org/logstash/logstash/logstash-1.4.0.tar.gz
tar zxvf logstash-1.4.0.tar.gz
rm -rf logstash-1.4.0.tar.gz
mv logstash-1.4.0 logstash
mkdir /etc/logstash
mkdir /var/log/logstash

#touch index.conf
cat >> /etc/logstash/index.conf<<EOF
input {
  syslog {
  type => "syslog"
  port => 514
  }
}

output {
  elasticsearch {
  host => "127.0.0.1"  }   
}
EOF

#add chkconfig
wget http://www.crazw.com/biglog_install/logstash.txt
mv logstash.txt /etc/init.d/logstash
chmod +x /etc/init.d/logstash
chkconfig --add logstash
chkconfig logstash on
service logstash start

echo "======================-====Logstash-index install completed========================="
}

function InstallClusterLogstash()
{
echo "=============================Install  Logstash-index================================"
#install logstash
cd /home
wget -O /home/logstash-1.4.0.tar.gz https://download.elasticsearch.org/logstash/logstash/logstash-1.4.0.tar.gz
tar zxvf logstash-1.4.0.tar.gz
rm -rf logstash-1.4.0.tar.gz
mv logstash-1.4.0 logstash
mkdir /etc/logstash
mkdir /var/log/logstash

#touch index.conf
cat >> /etc/logstash/index.conf<<EOF
input {
  syslog {
  type => "syslog"
  port => 514
  }
}

output {
  elasticsearch {
  host => "127.0.0.1" cluster => "${clustername}" }   
}
EOF

#add chkconfig
wget http://www.crazw.com/biglog_install/logstash.txt
mv logstash.txt /etc/init.d/logstash
chmod +x /etc/init.d/logstash
chkconfig --add logstash
chkconfig logstash on
/etc/init.d/logstash start

echo "===========================Logstash-index install completed========================="
}


function InstallElasticsearch()
{
echo "==============================Install Elasticsearch================================="
#download 
cd /tmp
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.1.0.tar.gz
tar zxvf elasticsearch-1.1.0.tar.gz
mv elasticsearch-1.1.0 /home/elasticsearch
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

#set infomation
sed -i  "s|# cluster.name: elasticsearch|cluster.name: ${clustername}|" /home/elasticsearch/config/elasticsearch.yml
sed -i  "s|# node.name: \"Franz Kafka\"|node.name: \"${nodename}\"|" /home/elasticsearch/config/elasticsearch.yml
sed -i  "326s|.*|discovery.zen.ping.unicast.hosts: [${clusterserverip}]|" /home/elasticsearch/config/elasticsearch.yml
sed -i  "s|# path.data: /path/to/data|path.data: ${pathdata}|" /home/elasticsearch/config/elasticsearch.yml

if [ $choiceelasticsearch = "y" ]; then     #master
    sed -i  's|# node.master: true|node.master: true|' /home/elasticsearch/config/elasticsearch.yml
    sed -i  's|# node.data: true|node.data: true|' /home/elasticsearch/config/elasticsearch.yml
else    #node
    sed -i  's|# node.master: false|node.master: false|' /home/elasticsearch/config/elasticsearch.yml
    sed -i  's|# node.data: true|node.data: true|' /home/elasticsearch/config/elasticsearch.yml
fi

#start the service
service elasticsearch start

#install the management tool of elasticsearch
cd /home/elasticsearch/
bin/plugin -install mobz/elasticsearch-head
bin/plugin -install lukas-vlcek/bigdesk

echo "=========================Elasticsearch install completed====================="
}

function InstallSingleElasticsearch()
{
echo "==============================Install Single Elasticsearch================================="
#download 
cd /tmp
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.1.0.tar.gz
tar zxvf elasticsearch-1.1.0.tar.gz
mv elasticsearch-1.1.0 /home/elasticsearch
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
bin/plugin -install lukas-vlcek/bigdesk

echo "=========================Single Elasticsearch install completed====================="
}

function InstallKibana()
{
echo "==================================Install Kibana ============================="
mkdir /home/wwwroot
cd /home/wwwroot
wget http://biglog.secon.me/biglog.tar.gz
tar zxvf biglog.tar.gz
rm -f biglog.tar.gz
echo "=============================Kibana install completed========================="
}

function InstallNginx()
{
echo "==================================Install Nginx ============================="
#install
cd /tmp
wget http://nginx.org/download/nginx-1.4.5.tar.gz
wget http://webserver.googlecode.com/files/pcre-8.10.tar.gz
tar zxvf nginx-1.4.5.tar.gz
tar zxvf pcre-8.10.tar.gz
groupadd www
useradd -g www -s /bin/false -M www
mkdir /usr/local/nginx
cd /tmp/nginx-1.4.5
./configure --user=www --group=www --prefix=/usr/local/nginx  --with-pcre=../pcre-8.10 --with-http_stub_status_module --with-http_gzip_static_module --without-mail_pop3_module --without-mail_smtp_module --without-mail_imap_module --without-http_uwsgi_module --without-http_scgi_module
make && make install

#add vhost 
sed -i "44s|.*|             root   /home/wwwroot/biglog;|" /usr/local/nginx/conf/nginx.conf
#cd /usr/local/nginx/conf
#mkdir /usr/local/nginx/conf/vhosts
#sed -i "117s|.*|include /usr/local/nginx/conf/vhosts/*.conf;|" nginx.conf
#wget http://www.crazw.com/biglog_install/biglog.conf
#mv biglog.conf /usr/local/nginx/conf/vhosts

#add chkconfig file
wget http://www.crazw.com/biglog_install/nginx
mv nginx /etc/init.d/nginx
chmod u+x /etc/init.d/nginx
chkconfig --add nginx1
chkconfig --level 345 nginx on

/etc/init.d/nginx restart

echo "=============================Nginx install completed========================="
}


#single or cluster,which one do you want to install?
echo "==========================="

  echo "Install single biglog,Please input y"
  echo "Install cluster biglog,Please input n "
  read -p "(Please input y or n):" isinstallbiglog

  case "$isinstallbiglog" in
  y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
  echo "You will install single biglog"
  isinstallbiglog="y"
  ;;
  n|N|No|NO|no|nO)
  echo "You will install cluster biglog"
  isinstallbiglog="n"
  ;;
  *)
  echo "INPUT error,Please run the shell again!"
  exit 1
  esac

if [ "$isinstallbiglog" = "y" ]; then
  #do you want to install the nginx?
  echo "==========================="

  installnginx="n"
  echo "Do you want to install the Nginx?"
  read -p "(Default no,if you want please input: y ,if not please press the enter button):" installnginx

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
else
  #do you want to install the awesant?
  echo "========================================================"
  read -p "(Please input your cluster name,eg: biglog ):" clustername
  echo "==========================="

  installawesant="n"
  echo "Do you want to install the Awesant?"
  read -p "(Default no,if you want please input: y ,if not please press the enter button):" installawesant

  case "$installawesant" in
  y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
  echo "You will install the Awesant!"
  installawesant="y"
  ;;
  n|N|No|NO|no|nO)
  echo "You will NOT install the Awesant!"
  installawesant="n"
  ;;
  *)
  echo "INPUT error,The Awesant will NOT install!"
  installawesant="n"
  esac

  if [ "$installawesant" == "y" ]; then
    InitInstall
    InstallAwesant
  else

  #do you want to install the logstash?
    echo "==========================="

    installlogstash="n"
    echo "Do you want to install the installlogstash?"
    read -p "(Default no,if you want please input: y ,if not please press the enter button):" installlogstash

    case "$installlogstash" in
    y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
    echo "You will install the Logstash!"
    installlogstash="y"
    ;;
    n|N|No|NO|no|nO)
    echo "You will NOT install the Logstash!"
    installlogstash="n"
    ;;
    *)
    echo "INPUT error,The Logstash will NOT install!"
    installlogstash="n"
    esac
  #do you want to install the elasticsearch?
    echo "==========================="

    installelasticsearch="n"
    echo "Do you want to install the elasticsearch?"
    read -p "(Default no,if you want please input: y ,if not please press the enter button):" installelasticsearch

    case "$installelasticsearch" in
    y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
    echo "You will install the elasticsearch!"
    installelasticsearch="y"
    ;;
    n|N|No|NO|no|nO)
    echo "You will NOT install the elasticsearch!"
    installelasticsearch="n"
    ;;
    *)
    echo "INPUT error,The elasticsearch will NOT install!"
    installelasticsearch="n"
    esac
    if [ "$installelasticsearch" == "y" ]; then
      choiceelasticsearch="n"
      echo "==========================="
      echo "Please choice which one do you want to install the elasticsearch? Master or Node"
      read -p "(Default Node,if you install the Master  input: y ,the Node press the enter button): " choiceelasticsearch

      echo "Please set the info!"
      # read -p "(Please input your cluster name,eg: biglog ):" clustername
      read -p "(Please input your node name, ): " nodename
      read -p "(Please input your all cluster server IPs,Format eg: \"10.18.157.3\", \"10.18.157.5\" ):" clusterserverip
      read -p "(Please input your path data,eg: /home/data ):" pathdata
      case "$choiceelasticsearch" in
      y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
      echo "You will install the Master elasticsearch!"
      choiceelasticsearch="y"
      ;;
      n|N|No|NO|no|nO)
      echo "You will install the Node elasticsearch!"
      choiceelasticsearch="n"
      ;;
      *)
      echo "INPUT error,You will install the Node elasticsearch!"
      choiceelasticsearch="n"
      esac
    fi  

  #do you want to install the kibana?
    echo "==========================="

    installkibana="n"
    echo "Do you want to install the kibana?"
    read -p "(Default no,if you want please input: y ,if not please press the enter button):" installkibana

    case "$installkibana" in
    y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
    echo "You will install the kibana!"
    installkibana="y"
    ;;
    n|N|No|NO|no|nO)
    echo "You will NOT install the kibana!"
    installkibana="n"
    ;;
    *)
    echo "INPUT error,The kibana will NOT install!"
    installkibana="n"
    esac

  #do you want to install the nginx?
    echo "==========================="

    installnginx="n"
    echo "Do you want to install the Nginx?"
    read -p "(Default no,if you want please input: y ,if not please press the enter button):" installnginx

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

    if [ "$installlogstash" == "y" ]; then
      InstallClusterLogstash
    fi  
    if [ "$installelasticsearch" == "y" ]; then
      InstallElasticsearch
    fi  
    if [ "$installkibana" == "y" ]; then
      InstallKibana
    fi  
    if [ "$installnginx" == "y" ]; then
      InstallNginx
    fi
  fi    
fi

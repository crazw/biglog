BIGLog说明文档
======

E-mail：craazw@gmail.com

Blog：http://www.crazw.com/

======

BIGLog集成：

      Awesant + Logstash + Elasticsearch +Kibana + Nginx ＋ Redis

======
安装方式：
      BIGLog单机版的服务器端一键部署包，适用于Centos 6.x 64位：

      cd /tmp
      wget http://update.biglog.org/biglog_standalone.sh
      chmod +x biglog_standalone.sh
      sh biglog_standalone.sh 2>&1 | tee /tmp/biglog_install.log
      注：装完请手动reboot下服务器。

   
======
单机版（Standalone）：

      Logstash-index（收集日志）+ Elasticsearch（索引）+ Kibana（前端） +Nginx（若已安装，只需配置对应vhost的server_name和root路径）


集群版（cluster）：参照分布式安装文档部署

   选择一：
   
        Awesant（发送日志）
        
   选择二：
   
        （需要确定集群名字：cluster.name）
        
        可选择性安装：Logstash-index（收集日志） or  Elasticsearch（索引） or  Kibana（前端）or Nginx（同上）
        
        其中：Elasticsearch安装需要指明是master or slave，
        
        以及node.name、server.ips、path.data等参数

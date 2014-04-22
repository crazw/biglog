biglog
======

E-mail：craazw@gmail.com
Blog：www.crazw.com

======

biglog集成：Awesant + Logstash + Elasticsearch +Kibana + Nginx

======
安装方式：
cd /tmp
wget http://www.crazw.com/biglog_install/biglog.sh

chmod +x biglog.sh

./biglog.sh 2>&1 | tee /tmp/biglog_install.log

======
单机版（single）：
Logstash-index（收集日志） + Elasticsearch（索引） + Kibana（前端） +Nginx（若已安装，只需配置对应vhost的server_name和root路径）

集群版（cluster）：
   选择一：
        Awesant（发送日志）
   选择二：
        （需要确定集群名字：cluster.name）
        可选择性安装：Logstash-index（收集日志） or  Elasticsearch（索引） or  Kibana（前端）or Nginx（同上）
        其中：Elasticsearch安装需要指明是master or slave，
        以及node.name、server.ips、path.data等参数

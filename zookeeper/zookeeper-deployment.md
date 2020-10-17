## init

Move everything to /opt or any comfy place. Our department will always put our stuff to /opt/**&lt;PROJECT_NAME>** and if it is being shared with multiple project, put it inside /opt/**nsl**

Basically this is my structure for zookeeper

```
/opt
    |
    ./nsl
        |
        ./apache-zookeeper-3.6.1-bin
            |
            + (bunch of files)
            + (bunch of directories)
            | ...
        ./zookeeper (ln -s to apache-zookeeper-3.6.1-bin)
            |
            + conf/zoo.cfg
            + bin/zkEnv.sh
            + bin/zkServer.sh
            + bin/zkCli.sh
            | ...
|
/etc/systemd/system
    |
    + zookeeper.service
```

For cluster setup,

```
                                             =|
              Load Balancer/VIP               |  for app not supporting
                      |                      =|    cloud library
                      |
                      +                      =|
       +--------------+--------------+        |        
     zookeeper1   zookeeper2   zookeeper3     |  or use cloud library for 
                                             =|    direct to node conf

```

Example running Solr cluster setup with supported multiple zookeeper cloud library

```
bin/solr start -e cloud -z localhost:2181,localhost:2182,localhost:2183 -noprompt
```



## pre-req
My requirement:
1. Put everything in sym linked directory. New package migration will not effecting external dependencies.
2. Always systemd
3. Always uniqed UID/GID for every user/system user
4. `--shell=/bin/false` for system user

Firewall using firewalld:
```
sudo firewall-cmd --add-port=2181/tcp
sudo firewall-cmd --add-port=2888/tcp
sudo firewall-cmd --add-port=3888/tcp

sudo firewall-cmd --runtime-to-permanent
```

> 
> **NOTE**: For production environment, please make sure you specifiying IP address of the source.
> 

## installing

Extract zookeeper to /opt/**&lt;PROJECT_NAME>** or /opt/**nsl**. For the sake of this doc, we called it as /opt/nsl.

```
curl -LO https://downloads.apache.org/zookeeper/zookeeper-3.6.1/apache-zookeeper-3.6.1-bin.tar.gz
tar xfz apache-zookeeper-*.tar.gz
ln -s apache-zookeeper-3.6.1-bin zookeeper
```

Setting up user and group for `zookeeper`

```
sudo groupadd zookeeper -g 5000
sudo useradd -r zookeeper --uid 5000 --shell /bin/false -g zookeeper
```

Check id and create data directory `$DATA_DIR` (make it as `/opt/nsl/zookeeper/data`)

```
sudo cat /etc/group | grep zoo
sudo id zookeeper

sudo mkdir /opt/nsl/zookeeper/data
```

Fixing the permission

```
sudo chown -R zookeeper:zookeeper /opt/nsl/apache-zookeeper-*
sudo chmod 777 /opt/nsl/zookeeper/bin/../logs/zookeeper_audit.log
```

`chmod 777 for audit.log` or change appropriate user for executing zkCli.sh later.


## configuring

Change zookeeper heap size to 2048Mb

```
sed -i -e "s/^ZK_SERVER_HEAP.*/ZK_SERVER_HEAP=2048/g" zookeeper/bin/zkEnv.sh
```

Configure `zoo.cfg`
```
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/opt/nsl/zookeeper/data
clientPort=2181
metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider
metricsProvider.httpPort=7000
metricsProvider.exportJvmInfo=true
server.1=nsl-solr-01.fairuz.local:2888:3888
server.2=nsl-solr-02.fairuz.local:2888:3888
server.3=nsl-solr-03.fairuz.local:2888:3888
#      ^ is the server id
#      each server should have their own unique id and store it inside myid file
```

Get current server id from server.`id` and put the id number to `$DATA_DIR/myid`

```
echo "1" > /opt/nsl/zookeeper/data/myid
```

for server.1, put 2 at server.2 and etc..

Now we need to configure systemd unit service.

```
[Unit]
Description=ZooKeeper Service
Documentation=http://zookeeper.apache.org
Requires=network.target
After=network.target

[Service]
Type=simple
User=zookeeper
Group=zookeeper
ExecStart=/opt/nsl/zookeeper/bin/zkServer.sh start-foreground /opt/nsl/zookeeper/conf/zoo.cfg
ExecStop=/opt/nsl/zookeeper/bin/zkServer.sh stop /opt/nsl/zookeeper/conf/zoo.cfg
ExecReload=/opt/nsl/zookeeper/bin/zkServer.sh restart /opt/nsl/zookeeper/conf/zoo.cfg
WorkingDirectory=/opt/nsl/zookeeper

[Install]
WantedBy=default.target
```

Reload daemon

```
sudo systemctl daemon-reload
```

> PROTIP: Open another shell and start `journalctl -fu zookeeper` (-f for follow, -u for unit followed by unit name) to start monitor before starting the unit service so that you can capture any error.


Start the service

```
sudo systemctl enable --now zookeeper
```


> TODO: add monitoring cluster using zkCli later.
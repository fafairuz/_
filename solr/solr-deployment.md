## init

Move everything to /opt or any comfy place. Our department will always put our stuff to /opt/**${PROJECT_NAME}** and if it is being shared with multiple project, put it inside /opt/**${DEPARTMENT_NAME}**

Basically this is my structure for solr

```
/opt
    |
    + ${PROJECT_NAME}
        |
        + solr-X.Y.Z
        |   |
            + (bunch of files)
            + (bunch of directories)
        |   | ...
        + solr (ln -s solr-X.Y.Z to here)
        |   |
            + conf/zoo.cfg
            + bin/zkEnv.sh
            + bin/zkServer.sh
            + bin/zkCli.sh
        |   | ...
        + data
            |
            + solr
        
|
/usr/lib/systemd/system
    |
    + solr.service

```

For cluster setup,

```
                                             =|
              Load Balancer/VIP               |  for app not supporting
                      |                      =|    cloud library
                      |
                      +                      =|
       +--------------+--------------+        |        
     solr1          solr2          solr3      |  or use cloud library for 
                                             =|    direct to node conf

```

Example running Solr cluster setup with supported multiple zookeeper cloud library

```
bin/solr start -f -c -z localhost:2181,localhost:2182
```

## Samples

Along this document, we will create based on these parameters. Feel free to change it to your current requirement/project-conditions. Refer to USER.md for NSL standardization.

```
PROJECT_NAME=miflash
PROJECT_UID=2099

SOLR_NAME=solr
SOLR_ID=5001
```

## Pre-req
My requirement:
1. Put everything in sym linked directory. New package migration will not effecting external dependencies.
2. Always systemd
3. Always uniqed UID/GID for every user/system user
4. `--shell=/bin/false` for system user

Firewall using firewalld:
```
sudo firewall-cmd --add-port=8983/tcp

sudo firewall-cmd --runtime-to-permanent
```

> 
> **NOTE**: For production environment, please make sure you specifiying IP address of the source.
> 

## User creation

This is done by following USER.md file

```
groupadd --guid 5001 solr
useradd --uid 5001 solr -g solr
```

If your are not yet setting up user for 

## Setting up directories

As shown before,
```
# this will create directory recursively
mkdir -p /opt/$PROJECT_NAME/data/solr
```

## Kernel Tuning

Solr will spawn into lots of processes and will consume large chunk of memory (for indexing).

We need to _unlock_ OS to open files more than 65000++ (`nofile`), expand number of processes (`nproc`) and no limit on memory lock (`memlock`).

> **CAUTIONS**: Expanding limits can cause OS to be unstable.

Add/edit in `/etc/security/limits.conf`

```
* soft nofile 65536
* hard nofile 131072
* soft nproc 65536
* hard nproc 65536
* soft memlock unlimited
* hard memlock unlimited

# End of file
```

Next, we need to allow map count and a little configuration for java take advantage of HugePage files (for GC?). 


First we need to calculate maximum HugePage. First, grep memory information by issuing command `cat /proc/meminfo | grep Huge`. This is an example.

```
AnonHugePages:    124928 kB
ShmemHugePages:        0 kB
HugePages_Total:       0
HugePages_Free:        0
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
Hugetlb:         3145728 kB
```

To calculate maximum total HugePages allowed, devide Hugetlb with Hugepagesize. From this example, 3145728 ÷ 2048 = 1536. Add/edit in `/etc/sysctl.conf` by specifying value from division to `vm.nr_hugepages`.

```
vm.max_map_count = 262144
vm.hugetlb_shm_group = 1001
vm.nr_hugepages = 1536
```

> **NOTE**: `hugetlb_shm_group` refers to group id. Either use existing or create a ethereal groups by `groupadd`.


## Installing


Extract solr to /opt/**${PROJECT_NAME}**.

```
# Get solr latest version here: https://lucene.apache.org/solr/downloads.html and follow links inside
curl -LO https://downloads.apache.org/lucene/solr/8.6.0/solr-8.6.0.tgz
tar xfz solr-8.6.0.tgz
```


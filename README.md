# docker-oracle-rac
Oracle 12.2 RAC on Docker

## Description

- Docker Host Information (on GCE)

|||
|-----|-----|
|Operating System|Centos Linux 7.x|
|OSType_Architecture|Linux_86_64|
|Kernel Version|3.10.0-693.5.2.el7.x86_64|
|CPUs|4|
|Memory|16GB|

- Network infomation

|Name|Address IP|Type IP|Interface|
|--------|--------|-------|-------|
|storage|192.168.100.20|Public IP|eth0|
|rac1|192.168.100.10|Public IP|eth0|
|rac1-vip|192.168.100.12|Virtual IP (vip)|-|
|rac1.priv|10.10.10.10|Private IP|eth1|
|rac2|192.168.100.11|Public IP|eth0|
|rac2-vip|192.168.100.13|Virtual IP (vip)|-|
|rac2.priv|10.10.10.11|Private IP|eth1|
|scan1.vip|192.168.100.14|SCAN IP|-|
|scan2.vip|192.168.100.15|SCAN IP|-|
|scan3.vip|192.168.100.16|SCAN IP|-|

- Storage infomation 

|Diskgroup name|use|asm device path|redundancy|size(GB|
|--------|--------|-------|-------|-------|
|VOTE|ocr and voting disk|/u01/asmdisks/disk6|external|47104|
|DATA|Database files|/u01/asmdisks/disk1,/u01/asmdisks/disk2|external|40
|FRA|flash recovery area|/u01/asmdisks/disk3|external|20


## Setup

### 1. Create swap

    dd if=/dev/zero of=/swapfile bs=16384 count=1M
    mkswap /swapfile
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
    chmod 600 /swapfile
    swapon -a

### 2. Install docker

    curl -fsSL https://get.docker.com/ | sh

### 3. enable docker service

    systemctl start docker 
    systemctl enable docker

### 4. Create asm disks

    mkdir -p /depo/asm/

    dd if=/dev/zero of=/depo/asm/disk1 bs=1024k count=20000
    dd if=/dev/zero of=/depo/asm/disk2 bs=1024k count=20000
    dd if=/dev/zero of=/depo/asm/disk3 bs=1024k count=20000

### 5. download Oracle 12c Release 2 (12.2) Clusterware and Database software and locate them on /media
    # ls -al /depo/12.2/
    total 6297260
    -rw-r--r--. 1 root root 3453696911 Feb 24  2017 linuxx64_12201_database.zip
    -rw-r--r--. 1 root root 2994687209 Oct 16 20:07 linuxx64_12201_grid_home.zip
    
### 6. cloning an Repository
    #git clone https://github.com/msavdert/docker-oracle-rac/






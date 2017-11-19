# docker-oracle-rac
Oracle 12.2 RAC on Docker

## Docker Host Information

### Google Cloud Engine
Kernel Version: 3.10.0-693.5.2.el7.x86_64
Operating System: CentOS Linux 7 (Core)
OSType: linux
Architecture: x86_64
CPUs: 4
Total Memory: 25.36GiB

## Setup

### 1.Create swap

dd if=/dev/zero of=/swapfile bs=16384 count=1M
mkswap /swapfile
echo "/swapfile none swap sw 0 0" >> /etc/fstab
chmod 600 /swapfile
swapon -a

### 2.Install docker

curl -fsSL https://get.docker.com/ | sh

systemctl start docker 
systemctl enable docker

### 3.Create asm disks

mkdir -p /depo/asm/

dd if=/dev/zero of=/depo/asm/disk1 bs=1024k count=20000
dd if=/dev/zero of=/depo/asm/disk2 bs=1024k count=20000
dd if=/dev/zero of=/depo/asm/disk3 bs=1024k count=20000
dd if=/dev/zero of=/depo/asm/disk4 bs=1024k count=20000
dd if=/dev/zero of=/depo/asm/disk5 bs=1024k count=20000

- Network infomation

|hostname/container name/vip|eth0|vxlan0(public)|vxlan1(internal)|vxlan2(asm)|
|--------|--------|-------|-------|-------|
|storage|10.153.0.50|-|-|-|
|node001|10.153.0.51|192.168.0.51|192.168.100.51|192.168.200.51|
|node002|10.153.0.52|192.168.0.52|192.168.100.52|192.168.200.52|
|node003|10.153.0.53|192.168.0.53|192.168.100.53|192.168.200.53|
|node001.vip|-|192.168.0.151|-|-|
|node002.vip|-|192.168.0.152|-|-|
|node003.vip|-|192.168.0.152|-|-|
|scan1.vip|-|192.168.0.31|-|-|
|scan2.vip|-|192.168.0.32|-|-|
|scan3.vip|-|192.168.0.33|-|-|






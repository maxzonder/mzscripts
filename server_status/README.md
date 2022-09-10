Script checks disk space, SMART status, RAM and CPU usage and sends info to telegram.

**to use `smartclt` script should be installed to root!**

1. Install

```
su -

mkdir -p /root/scripts/server_status
cd /root/scripts/server_status

wget -O server_status.sh https://raw.githubusercontent.com/maxzonder/mzscripts/main/server_status/server_status.sh
wget https://raw.githubusercontent.com/maxzonder/mzscripts/main/server_status/server_status.ini

chmod +x server_status.*
```

2. Prepare `server_status.ini`:

Install `smartmontools`:

```
apt-get update && apt-get install smartmontools -y
```

Scan drives and put them into DRIVES var, separated with space.
(not for VPS)

```
smartctl --scan
```
output example:
```
/dev/nvme0 -d nvme # /dev/nvme0, NVMe device
/dev/nvme1 -d nvme # /dev/nvme1, NVMe device
```

Output disk space and choose mount point, fill MOUNTS with values separated with space

```
df -h
```

output example

```
Filesystem      Size  Used Avail Use% Mounted on
udev             32G     0   32G   0% /dev
tmpfs           6.3G  948K  6.3G   1% /run
/dev/md2        921G  101G  774G  12% /
tmpfs            32G  156K   32G   1% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs            32G     0   32G   0% /sys/fs/cgroup
/dev/md1        485M  100M  360M  22% /boot
tmpfs           6.3G     0  6.3G   0% /run/user/0
```

`/dev/md2` is a right mount point. 

Run
```
bash server_status.sh
```

Add to cron

# Info
Script checks disk space, SMART status (on dedicated servers), RAM and CPU usage and sends info to telegram.

# Dependencies and settings
1. Script must be installed as `root` to read disks' SMART status. No `root` needed if you disable SMART checking function. It is unable to check SMART status on VPS/VDS.
2. `smartmontools` is needed to check SMART status.
3. `bsdmainutils` is needed to format output with `columns` command (may absent on some ISOs).

## `server_status.ini` format

Example:

```ini
SERVER_NAME="HETZ-01"
SERVER_INFO="OSMOSIS, COSMOS-RPC, HERMES"
MOUNTS="/dev/nvme0n1p3 /dev/nvme1n1 /dev/nvme2n1"
MOUNTS_NAMES="/root /mnt/disk1 /mnt/disk2"
DRIVES="/dev/nvme0 /dev/nvme1 /dev/nvme2"
STORAGE_TRESHOLD_YELLOW=70
STORAGE_TRESHOLD_RED=85
SMART_TRESHOLD_YELLOW=80
SMART_TRESHOLD_RED=90
MEMORY_TRESHOLD_YELLOW=85
MEMORY_TRESHOLD_RED=95
CPU_TRESHOLD_YELLOW=80
CPU_TRESHOLD_RED=90
TG_CHAT_ID="123123123"
TG_TOKEN="23434343434:AAbbbcccabcabcacbabcabcabcabc"


```
_File must end with a single blank line!_

`SERVER_NAME` - any server name,

`SERVER_INFO` - any server info, e.g. nodes list,

`MOUNTS` - mount points separated by space (see instructions below),

`MOUNTS_NAMES` - human readable names for every mount point, separated by space,

`DRIVES` - server drives separated by space (see instructions below),

`*_TRESHOLD*` - config tresholds (%) for output status. There are 3 possible statuses: OK, :warning: , :red_circle:.

`TG_CHAT_ID` - your telegram account id,

`TG_TOKEN` - your telegram bot HTTP API.


# Install

Login as root (you can skip this if you dont need SMART checking functionality).

```bash
su -
```

Download script

```bash
mkdir -p $HOME/scripts/server_status
cd $HOME/scripts/server_status

wget -O server_status.sh https://raw.githubusercontent.com/maxzonder/mzscripts/main/server_status/server_status.sh
wget https://raw.githubusercontent.com/maxzonder/mzscripts/main/server_status/server_status.ini

chmod +x server_status.*
```

Install `smartmontools` (you can skip this if you don't need SMART checking functionality):

```bash
apt-get update && apt-get install smartmontools -y
```

# Prepare `server_status.ini`:

## Prepare `MOUNTS` and `MOUNTS_NAMES`

Output disk space and choose mount point you want to track, fill `MOUNTS` and `MOUNTS_NAMES` with values separated by space.

```bash
df -h
```

Output example:

```
Filesystem      Size  Used Avail Use% Mounted on
udev             32G     0   32G   0% /dev
tmpfs           6.3G 1008K  6.3G   1% /run
/dev/nvme0n1p3  906G  199G  661G  24% /
tmpfs            32G     0   32G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs            32G     0   32G   0% /sys/fs/cgroup
/dev/nvme0n1p2  975M  166M  758M  18% /boot
/dev/nvme1n1p1  938G   77M  891G   1% /mnt/disk1
/dev/nvme2n1p1  938G   77M  891G   1% /mnt/disk2
tmpfs           6.3G     0  6.3G   0% /run/user/9001
tmpfs           6.3G     0  6.3G   0% /run/user/0
```

Filling `MOUNTS` and `MOUNTS_NAMES` example:

```ini
...
MOUNTS="/dev/nvme0n1p3 /dev/nvme1n1p1 /dev/nvme2n1p1"
MOUNTS_NAMES="/root /mydisk1 /mydisk2"
...
```

## Prepare `DRIVES`

Leave `DRIVES=""` empty on VPS/VDS to **disable** SMART checking functionality.

Scan drives on dedicated server and put them into the `DRIVES="..."`, separated by space.

```bash
smartctl --scan
```

Output example:

```
/dev/nvme0 -d nvme # /dev/nvme0, NVMe device
/dev/nvme1 -d nvme # /dev/nvme1, NVMe device
/dev/nvme2 -d nvme # /dev/nvme2, NVMe device
```

Filling `DRIVES` example with above output:

```ini
...
DRIVES="/dev/nvme0 /dev/nvme1 /dev/nvme2"
...
```

Save changes to `server_status.ini` and run the script to check.

# Run

```bash
bash server_status.sh
```

If output ok, create cron task.

# Add to cron
Add to cron e.g. every day "At 9:00." (change `root` to your home_dir if needed):

```
0 9 * * * /bin/bash /root/scripts/server_status/server_status.sh
```

# How to update script

```bash
# switch to root if needed
su -

cd $HOME/scripts/server_status
mv server_status.sh server_status.old
wget -O server_status.sh https://raw.githubusercontent.com/maxzonder/mzscripts/main/server_status/server_status.sh
chmod +x server_status.sh
```

# Preview
![image](https://user-images.githubusercontent.com/73627790/189493552-fe5fea49-16b9-4342-b2a2-ca2550692aa1.png)

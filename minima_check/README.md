# Install
Download script:
```
mkdir -p $HOME/minima_check && cd $HOME/minima_check

wget -O minima_check.sh https://raw.githubusercontent.com/maxzonder/mzscripts/main/minima_check/minima_check.sh
wget https://raw.githubusercontent.com/maxzonder/mzscripts/main/minima_check/minima_check.ini
wget https://raw.githubusercontent.com/maxzonder/mzscripts/main/minima_check/minima_check.csv
```
Fill `minima_check.csv` with your datas and `minima_check.ini` with your Telegram HTTP API and account ID (call [@BotFather](https://t.me/BotFather) and [@getmyid_bot](https://t.me/getmyid_bot)).

Files must end with a single blank line.

Make executable and execute:
```
chmod +x minima_check.*
bash minima_check.sh
```

Add to cron e.g. every hour (change `root` to username if needed):
```
0 */1 * * *  /bin/bash /root/scripts/minima_check.sh
```

## `minima_check.ini` format

```
TG_CHAT_ID="123123123"
TG_TOKEN="123123123:abcabcbacbacbacabacbacbacbacb"
CURL_TIMEOUT=3

```

`TG_CHAT_ID` - your telegram account id,

`TG_TOKEN` - your telegram HTTP API,

`CURL_TIMEOUT` - timeout to curl server (default is 15 seconds).

_File must end with a single blank line._

## `minima_check.csv` format

```
account_name1,server_name1,server_ip1,your_id1
account_name2,server_name2,server_ip2:port2,your_id2
...
account_name5,server_name5,server_ip5,your_id5

```

`account_name`, `server_name`- any names you want,

`server_ip`- server IP e.g. `111.222.333.444`,

`port` (optional) - server IP port , if not specified, then = `9002`,

`your_id` - your minima node id, e.g. `12345522-d4b4-32d6-8abc-e345a046528a1`.

_File must end with a single blank line._

# How to update script

```
cd $HOME/minima_check
cp minima_check.sh minima_check.old
wget -O minima_check.sh https://raw.githubusercontent.com/maxzonder/mzscripts/main/minima_check/minima_check.sh
chmod +x minima_check.sh
```

## Preview
![image](https://user-images.githubusercontent.com/73627790/184517723-74e618df-3bcd-4e68-a929-50cc82d353d4.png)



Parse RESTAKE.APP logs, add some alerts (low balance, restake failed, no logs) and send to TG

# Install
Download script to restake bot server:
```
mkdir -p $HOME/scripts/restake_report && cd $HOME/scripts/restake_report

wget -O restake_report.sh https://raw.githubusercontent.com/maxzonder/mzscripts/main/restake_report/restake_report.sh
wget -O restake_report.ini https://raw.githubusercontent.com/maxzonder/mzscripts/main/restake_report/restake_report.ini
```

## `restake_report.ini` format

```
TG_CHAT_ID="123123123"
TG_TOKEN="123123123:abcabcbacbacbacabacbacbacbacb"
BALANCE_ALERT="10"
ETH_CHAINS="Evmos Canto"
```

`TG_CHAT_ID` - your telegram account id,

`TG_TOKEN` - your telegram HTTP API,

`BALANCE_ALERT` - alert if bot balance < 10 TOKENS,

`ETH_CHAINS` - list of chains with denom 10^18 (separated by space)

_File must end with a single blank line._


Adjust `--since` value if needed here:
```
 journalctl -u restake --since today -o cat --no-pager |
```


Make executable and execute:
```
chmod +x restake_report.*
bash restake_report.sh
```

Add to cron after restake bot complete work (change `root` to your $HOME dir if needed):

e.g. restake time is 18.30, run script at 18.40

```
40 18 * * *  /bin/bash /root/scripts/restake_report/restake_report.sh
```

# How to update script

```
cd $HOME/scripts/restake_report
cp restake_report.sh restake_report.old
wget -O restake_report.sh https://raw.githubusercontent.com/maxzonder/mzscripts/main/restake_report/restake_report.sh
chmod +x restake_report.sh
```

## Preview
![image](https://user-images.githubusercontent.com/73627790/222178628-a3337325-8a58-41ba-9f22-a4ff2feb1783.png)

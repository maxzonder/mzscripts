Parse RESTAKE.APP logs, add some alerts (low balance, restake failed, no logs) and send to TG

# Install
Download script to restake bot server:
```
mkdir -p $HOME/scripts/restake_report && cd $HOME/scripts/restake_report

wget -O restake_report.sh https://raw.githubusercontent.com/maxzonder/mzscripts/main/restake_report/restake_report.sh
```

Set vars:
```
TG_CHAT_ID="3xxxxxxx"
TG_TOKEN="2xxxxxxxxxx:xxxxxxxxxxxxxxxxx"
```

Adjust `--since` value if needed here:
```
 journalctl -u restake --since today -o cat --no-pager |
```

Adjust minimum token balance if needed here:
```
 if (( ${balance%.*} < 10 )); then
```

Make executable and execute:
```
chmod +x restake_report.sh
bash restake_report.sh
```

Add to cron after restake bot complete work (change `root` to your $HOME dir if needed):

e.g. restake time is 18.30, run script at 18.40

```
40 18 * * *  /bin/bash /root/scripts/restake_report/restake_report.sh
```

## Preview
![image](https://user-images.githubusercontent.com/73627790/222178628-a3337325-8a58-41ba-9f22-a4ff2feb1783.png)

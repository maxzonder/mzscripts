Download
```
mkdir -p $HOME/minima_check && cd $HOME/minima_check

wget -O minima_check.sh https://raw.githubusercontent.com/maxzonder/mzscripts/main/minima_check/minima_check.sh
wget https://raw.githubusercontent.com/maxzonder/mzscripts/main/minima_check/minima_check.ini
wget https://raw.githubusercontent.com/maxzonder/mzscripts/main/minima_check/minima_check.csv
```
Fill `minima_check.csv` with your datas and `minima_check.ini` with your Telegram HTTP API and account ID (call `@bot_father` and `@getmyid_bot`).

The last line of the files should be empty line!

Make execute and execute
```
chmod +x minima_check.*
bash minima_check.sh
```

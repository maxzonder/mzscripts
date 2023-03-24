#!/bin/bash

# Load config
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

IFS="="
while read -r name value || [[ $name && $value ]] 
do
  if [[ -n "${name}" && "${name}" != [[:blank:]#]* ]]; then
    eval ${name}="${value}"
  fi
done < $SCRIPT_DIR/minima_check.ini

# START

output_status="ACCOUNT,VERSION,BLOCK,BAL\n"
output_status+="=======,=======,=====,===\n"
IFS=","
while read -r ACCOUNT_NAME SERVER_NAME SERVER_IP ACCOUNT_ID || [[ $ACCOUNT_NAME ]]
do
  # parse ip
  ip=$(awk -F ":" '{print $1}' <<< $SERVER_IP)
  port=$(awk -F ":" '{print $2}' <<< $SERVER_IP)
  if [ -z "$port" ]; then port=9005; fi
  SERVER_IP="$ip:$port"
  # check id
  output+="$ACCOUNT_NAME,$SERVER_NAME,"
  # check version and block
  status_query=$(curl -s --max-time $CURL_TIMEOUT $SERVER_IP/status)
  balance_query=$(curl -s --max-time $CURL_TIMEOUT $SERVER_IP/balance | jq -r .response[].sendable)
  current_version=$(echo "$status_query" | jq -r .response.version)
  current_block=$(echo "$status_query" | jq -r .response.chain.block)
  current_block_time=$(echo "$status_query" | jq -r .response.chain.time)
  if [ -z "$current_version" ]; then current_version="ERROR!"; fi
  if [ -z "$current_block" ]; then current_block="ERROR!"; fi
  output_status+="$ACCOUNT_NAME,$current_version,$current_block,$balance_query\n"
done < $SCRIPT_DIR/minima_check.csv

output_status=$(echo -e "$output_status" | column -s "," -t)

# Send Message
message=$(echo -e "<b>MINIMA CHECK</b> | $(date +'%Y-%m-%d, %H:%M:%S')\n\n<pre>${output_status}</pre>\n\n<b>${current_block}</b> block time:\n<pre>${current_block_time}</pre>")

if [ -n "$TG_TOKEN" ]; then
  curl -s --data "text=${message}" --data "chat_id=${TG_CHAT_ID}" --data "parse_mode=html" 'https://api.telegram.org/bot'${TG_TOKEN}'/sendMessage' > /dev/null
fi

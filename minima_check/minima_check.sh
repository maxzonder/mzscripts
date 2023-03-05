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

output="ACCOUNT,SERVER,REWARD, \n"
output+="=======,======,======, \n"
output_status="ACCOUNT,VERSION,BLOCK\n"
output_status+="=======,=======,===== \n"
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
  current_query=$(curl -s --max-time $CURL_TIMEOUT $SERVER_IP/incentivecash)
  #check timeout
  error=$(echo "$current_query" | jq -r .error)
  if [[ "$error" = "connect timed out" || -z "$current_query" ]]; then
    output+="TIMEOUT,\xE2\x9D\x97\n"
  else
    current_id=$(echo "$current_query" | jq -r .response.uid)
    if [ "$current_id" = "$ACCOUNT_ID" ]; then
      rewards=$(echo "$current_query" | jq -r .response.details.rewards.dailyRewards)
      if [ -n "$rewards" ]; then
        output+="$rewards,OK\n"
      else 
        output+="???,OK?\n"  
      fi
    else  
      if [ -z "$current_id" ]; then
        output+="NO_ID,\xE2\x9D\x97\n"
        output+="...assign_ID,"
      else
        output+="BAD_ID,\xE2\x9D\x97\n"
        output+="....assign_ID,"
      fi
      # try to correct id    
      do_correct=$(curl -s --max-time $CURL_TIMEOUT $SERVER_IP/incentivecash%20uid:$ACCOUNT_ID)
      sleep 1
      # check id again
      current_query=$(curl -s --max-time $CURL_TIMEOUT $SERVER_IP/incentivecash)
      current_id=$(echo "$current_query" | jq -r .response.uid)
      rewards=$(echo "$current_query" | jq -r .response.details.rewards.dailyRewards)
      if [ "$current_id" = "$ACCOUNT_ID" ]; then
        output+="OK,,\n"
        output+="${ACCOUNT_NAME},${SERVER_NAME},"
        output+="$rewards,OK\n"
      else 
        output+="FAIL!,,\n"
      fi
    fi 
  fi  
  # check version and block
  status_query=$(curl -s --max-time $CURL_TIMEOUT $SERVER_IP/status)
  current_version=$(echo "$status_query" | jq -r .response.version)
  current_block=$(echo "$status_query" | jq -r .response.chain.block)
  if [ -z "$current_version" ]; then current_version="ERROR!"; fi
  if [ -z "$current_block" ]; then current_block="ERROR!"; fi
  output_status+="$ACCOUNT_NAME,$current_version,$current_block\n"
done < $SCRIPT_DIR/minima_check.csv

output=$(echo -e "$output" | column -s "," -t | sed -e '/...assign_ID/s/.*/<\/pre><i> & <\/i><pre>/')
output=$(echo -e "$output" | sed  's/...assign_ID/...trying to assign right ID -/')

output_status=$(echo -e "$output_status" | column -s "," -t)

# Send Message
message=$(echo -e "<b>MINIMA CHECK</b> | $(date +'%Y-%m-%d, %H:%M:%S')\n\n<pre>${output}</pre>\n\n<pre>${output_status}</pre>")

if [ -n "$TG_TOKEN" ]; then
  curl -s --data "text=${message}" --data "chat_id=${TG_CHAT_ID}" --data "parse_mode=html" 'https://api.telegram.org/bot'${TG_TOKEN}'/sendMessage' > /dev/null
fi

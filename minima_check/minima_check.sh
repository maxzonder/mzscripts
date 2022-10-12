#!/bin/bash

# Load config
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

IFS="="
while read -r name value
do
  if [[ -n "${name}" && "${name}" != [[:blank:]#]* ]]; then
    eval ${name}="${value}"
  fi
done < $SCRIPT_DIR/minima_check.ini

# START

output="ACCOUNT,SERVER,REWARD, "$'\n'
output+="=======,======,======, "$'\n'
output_status="ACCOUNT,VERSION,BLOCK"$'\n'
output_status+="=======,=======,===== "$'\n'
while IFS="," read -r ACCOUNT_NAME SERVER_NAME SERVER_IP ACCOUNT_ID
do
  # parse ip
  ip=$(echo "${SERVER_IP}" | awk -F ":" '{print $1}')
  port=$(echo "${SERVER_IP}" | awk -F ":" '{print $2}')
  if [ -z "${port}" ]; then port=9005; fi
  SERVER_IP="${ip}:${port}"
  # check id
  current_query=$(curl -s --max-time $CURL_TIMEOUT ${SERVER_IP}/incentivecash)
  current_id=$(echo "${current_query}" | jq -r .response.uid)
  output+="${ACCOUNT_NAME},${SERVER_NAME},"
  if [ "${current_id}" = "${ACCOUNT_ID}" ]; then
    rewards=$(echo "${current_query}" | jq -r .response.details.rewards.dailyRewards)
    if [ -n "${rewards}" ]; then
      output+="${rewards},OK"$'\n'
    else 
      output+="???,OK?"$'\n'  
    fi
  else  
    if [ -z "${current_id}" ]; then
      output+="NO_ID,\xE2\x9D\x97"$'\n'
      output+="...assign_id,,,"$'\n'
    else
      output+="BAD_ID,\xE2\x9D\x97"$'\n'
      output+="...assign_id,,,"$'\n'
    fi
    # try to correct id    
    output+="${ACCOUNT_NAME},${SERVER_NAME},"
    do_correct=$(curl -s --max-time $CURL_TIMEOUT ${SERVER_IP}/incentivecash%20uid:${ACCOUNT_ID})
    sleep 1
    # check id again
    current_query=$(curl -s --max-time $CURL_TIMEOUT ${SERVER_IP}/incentivecash)
    current_id=$(echo "${current_query}" | jq -r .response.uid)
    rewards=$(echo "${current_query}" | jq -r .response.details.rewards.dailyRewards)
    if [ "${current_id}" = "${ACCOUNT_ID}" ]; then
      output+="${rewards},\xE2\x9C\x94"$'\n'
    else 
      output+="FAIL!,\xE2\x9C\x96"$'\n'
    fi
  fi  
  # check version and block
  status_query=$(curl -s --max-time $CURL_TIMEOUT ${SERVER_IP}/status)
  current_version=$(echo "${status_query}" | jq -r .response.version)
  current_block=$(echo "${status_query}" | jq -r .response.chain.block)
  if [ -z "${current_version}" ]; then current_version="ERROR!"; fi
  if [ -z "${current_block}" ]; then current_block="ERROR!"; fi
  output_status+="${ACCOUNT_NAME},${current_version},${current_block}"$'\n' 
done < $SCRIPT_DIR/minima_check.csv

output=$(echo "${output}" | column -s "," -t | sed 's/^...assign_id/<\/pre><i>...trying to assign right ID<\/i><pre>/g')
output_status=$(echo "${output_status}" | column -s "," -t)

# Send Message
message=$(echo -e "<b>MINIMA CHECK</b> | $(date +'%Y-%m-%d, %H:%M:%S')\n\n<pre>${output}</pre>\n\n<pre>${output_status}</pre>")

if [ -n "${TG_TOKEN}" ]; then
  curl -s --data "text=${message}" --data "chat_id=${TG_CHAT_ID}" --data "parse_mode=html" 'https://api.telegram.org/bot'${TG_TOKEN}'/sendMessage' > /dev/null
fi

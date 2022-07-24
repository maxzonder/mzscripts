#!/bin/bash

# Load config
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

IFS="="
while read -r name value
do
  eval ${name}="${value}"
done < $SCRIPT_DIR/minima_check.ini

# START

output="ACCOUNT,SERVER,REWARD, "$'\n'
output+="=======,======,======, "$'\n'
while IFS="," read -r ACCOUNT_NAME SERVER_NAME SERVER_IP ACCOUNT_ID
do
  # check id
  current_id=$(curl -s --max-time $CURL_TIMEOUT ${SERVER_IP}:9002/incentivecash | jq -r .response.uid)
  output+="${ACCOUNT_NAME},${SERVER_NAME}," 
  if [ "${current_id}" = "${ACCOUNT_ID}" ]; then
    rewards=$(curl -s --max-time $CURL_TIMEOUT ${SERVER_IP}:9002/incentivecash | jq -r .response.details.rewards.dailyRewards)
    output+="${rewards},OK"$'\n'
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
    do_correct=$(curl -s --max-time $CURL_TIMEOUT ${SERVER_IP}:9002/incentivecash%20uid:${ACCOUNT_ID})
    sleep 1
    # check id again
    current_id=$(curl -s --max-time $CURL_TIMEOUT ${SERVER_IP}:9002/incentivecash | jq -r .response.uid)
    rewards=$(curl -s --max-time $CURL_TIMEOUT ${SERVER_IP}:9002/incentivecash | jq -r .response.details.rewards.dailyRewards)
    if [ "${current_id}" = "${ACCOUNT_ID}" ]; then
      output+="${rewards},\xE2\x9C\x94"$'\n'
    else 
      output+="FAIL!,\xE2\x9C\x96"$'\n'
    fi
  fi   
done < $SCRIPT_DIR/minima_check.csv

output=$(echo "${output}" | column -s "," -t | sed 's/^...assign_id/<\/pre><i>...trying to assign right ID<\/i><pre>/g')

# Send Message
message=$(echo -e "<b>MINIMA CHECK</b> | $(date +'%Y-%m-%d, %H:%M:%S')\n\n<pre>${output}</pre>")

if [ -n "${TG_TOKEN}" ]; then
  curl -s --data "text=${message}" --data "chat_id=${TG_CHAT_ID}" --data "parse_mode=html" 'https://api.telegram.org/bot'${TG_TOKEN}'/sendMessage' > /dev/null
fi

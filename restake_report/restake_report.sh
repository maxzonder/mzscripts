#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

IFS="="
while read -r name value || [[ $name && $value ]]; 
do
  eval ${name}="${value}"
done < $SCRIPT_DIR/restake_report.ini

IFS=" " read -a ethChainsArray <<< $ETH_CHAINS

FILE_STATE=$SCRIPT_DIR/restake_state.txt
FILE_MESSAGE=$SCRIPT_DIR/restake_message.txt

rm -f $FILE_STATE
echo -e "\\xF0\\x9F\\x93\\xAB <b>RESTAKE</b> | $(date +'%a %d %b %Y %T %Z')\n" > $FILE_MESSAGE

journalctl -u restake --since today -o cat --no-pager |
while IFS="" read -r line || [ -n "$p" ]
do
  line=$(awk '{$1=""}1' <<< $line)
  line="${line:1}"

  if grep -q "Loaded" <<< "$line" && [ -z "${ATTEMPT}" ]; then
    ATTEMPT=1
    TX=""
    CHAIN=$(awk '{print $2}' <<< $line)
    echo -n "${CHAIN}:," >> $FILE_STATE
    echo $line | awk '{print "<b>"$1" "$2"</b>"}' >> $FILE_MESSAGE
    continue
  fi

  if grep -q "Not an operator" <<< "$line" && (( ATTEMPT == 1 )); then
    echo "-" >> $FILE_STATE
    echo "${line}" >> $FILE_MESSAGE
    continue
  fi
  
  if grep -q "balance" <<< "$line" && (( ATTEMPT == 1 )); then
    denom=1000000  
    for ethchain in ${ethChainsArray[@]}; do
      if [[ "$CHAIN" == "$ethchain" ]]; then
        denom=1000000000000000000
      fi
    done
    balance=$(awk -v denom="$denom" '{print $4/denom}' <<< $line)
    token=$(awk '{print toupper($5)}' <<< $line)
    token="${token:1}"
    alert=""
    if (( ${balance%.*} < BALANCE_ALERT )); then
      alert="\\xE2\\x9A\\xA0" 
    fi
    echo -e "Bot balance is $balance $token $alert" >> $FILE_MESSAGE
    continue
  fi
  
  if grep -q "addresses" <<< "$line" && (( ATTEMPT == 1 )); then
    DELEGATORS=$(awk '{print $2}' <<< $line)
    echo "${DELEGATORS} delegators" >> $FILE_STATE
    echo "${line}" >> $FILE_MESSAGE
    continue
  fi

  if grep -q "Failed attempt" <<< "$line" ; then
    ATTEMPT=2
    echo "${line}" >> $FILE_MESSAGE
    continue
  fi
  
  if grep -q "Autostake completed" <<< "$line" ; then
    echo "${line}" >> $FILE_MESSAGE
    continue
  fi
  
  if grep -q "Autostake finished" <<< "$line" ; then
    ATTEMPT=""
    echo -e "${line}" >> $FILE_MESSAGE
    continue
  fi

  if grep -q "Autostake failed after" <<< "$line" ; then
    echo "${line}" >> $FILE_MESSAGE
    continue
  fi
  
  if grep -q "Autostake failed" <<< "$line" ; then  
    ATTEMPT=""
    echo -e "\\xF0\\x9F\\x94\\xB4 ${line}" >> $FILE_MESSAGE              # red circle alert if autostake failed
    continue
  fi
   
  if grep -q "TX 1: Failed" <<< "$line" && [ -z "${TX}" ]; then
    TX=1
    echo "${line}" | awk -F ';' '{print "<pre>"substr($2,2),$3"</pre>"}' >> $FILE_MESSAGE
    continue
  fi
done 

MESSAGE=$(cat $FILE_MESSAGE)

if [ -f $FILE_STATE ]; then
  MESSAGE+=$'\n\n'"<pre>"$(cat $FILE_STATE | column -s "," -t)"</pre>"
else
  MESSAGE+=$(echo -e "\n\n\\xF0\\x9F\\x94\\xB4 No logs since today ")    # red circle alert no logs
fi

if [ -n "${TG_TOKEN}" ]; then
  curl -s --data "text=${MESSAGE}" --data "chat_id=${TG_CHAT_ID}" --data "parse_mode=html" 'https://api.telegram.org/bot'${TG_TOKEN}'/sendMessage' > /dev/null
fi

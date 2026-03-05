#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPT_NAME=$(basename "$BASH_SOURCE") 
[ -f "$SCRIPT_DIR/${SCRIPT_NAME%.*}.ini" ] || { echo "ERROR: ${SCRIPT_NAME%.*}.ini not found"; exit 1; }

IFS="="
while read -r name value || [[ $name && $value ]] 
do
  if [[ -n "${name}" && "${name}" != [[:blank:]#]* ]]; then
    eval ${name}="${value}"
  fi
done < $SCRIPT_DIR/${SCRIPT_NAME%.*}.ini

IFS=" " read -a ethChainsArray <<< $ETH_CHAINS

FILE_STATE=$SCRIPT_DIR/restake_state.txt
FILE_MESSAGE=$SCRIPT_DIR/restake_message.txt

rm -f $FILE_STATE
echo -e "\\xF0\\x9F\\x93\\xAB <b>RESTAKE</b> | $(date +'%a %d %b %Y %T %Z')\n" > $FILE_MESSAGE

ATTEMP=0

journalctl -u restake --since "today" -o cat --no-pager |
while IFS="" read -r line || [ -n "$line" ]
do

  line=$(awk '{$1=""}1' <<< $line)
  line=$(awk '{$1=""}1' <<< $line)
  line="${line:1}"

  if grep -q "Loaded chain" <<< "$line" && (( ATTEMP == 0 )); then
    ATTEMP=1 # new chain parsing started
    delegators=""
    chain=$(echo "$line" | grep -oP 'prettyName=\K\w+')
    echo -n "${chain}:," >> $FILE_STATE
    echo "<b>Loaded ${chain}</b>"  >> $FILE_MESSAGE
    continue
  fi
  
  if grep -q "Found addresses" <<< "$line" && (( ATTEMP == 1 )); then
    delegators="$(echo "$line" | grep -oP 'count=\K\w+') delegators"
    echo "Found ${delegators} addresses with valid grants" >> $FILE_MESSAGE
    continue
  fi

  if grep -q "Fetched bot balance" <<< "$line" && (( ATTEMP == 1 )); then
    exponent=6  
    for ethchain in ${ethChainsArray[@]}; do
      if [[ "$chain" == "$ethchain" ]]; then
        exponent=18
        break
      fi
    done
    balance=$(echo "$line" | grep -oP 'amount=\K\w+')
    denom=$(echo "$line" | grep -oP 'denom=\K\w+')
    symbol="${denom:1}"
    symbol="${symbol^^}"
    denomed_amount=$(echo "scale=2; x=${balance}/(10^${exponent}); if(x==0) print \"0.0\" else if(x>0 && x<1) print 0,x else if(x>-1 && x<0) print \"-0\",-x else print x" | bc)
    denomed_amount=$(echo "$denomed_amount" | sed 's/\.0*$//;s/\([0-9]*\.[0-9]*[1-9]\)0*$/\1/')
    (( $(echo "$denomed_amount < $BALANCE_ALERT" | bc) )) && alert=" \\xF0\\x9F\\x9F\\xA1" || alert=""
    echo -e "Bot balance is $denomed_amount ${symbol}${alert}" >> $FILE_MESSAGE
    continue
  fi

  if grep -q "Autostake finished for" <<< "$line"; then
    ATTEMP=0 # finished parsing chain
    echo "${delegators}" >> $FILE_STATE
    echo "Autostake finished" >> $FILE_MESSAGE
    continue
  fi

  if grep -q "Autostake failed for" <<< "$line" ; then  
    ATTEMP=0 # finished parsing chain
    [[ -z "$delegators" ]] && delegators="N/A"
    echo "${delegators}" >> $FILE_STATE  
    echo -e "\\xF0\\x9F\\x94\\xB4 Autostake failed" >> $FILE_MESSAGE
    continue
  fi

  if grep -q "Not an operator" <<< "$line"; then
    delegators="NaO"
    echo -e "\\xF0\\x9F\\x9F\\xA1 Not an operator" >> $FILE_MESSAGE
    continue
  fi

  # inside attemps

  if grep -q "Failed attempt" <<< "$line" ; then
    ((ATTEMP++)) # skip "Fetched bot balance" and "Found addresses" parsing inside attemps iterations
    echo "${line}" >> $FILE_MESSAGE
    continue
  fi

  if grep -q "TX 1: Failed" <<< "$line" && (( ATTEMP == 2 )); then
    ((ATTEMP++)) # skip next "TX 1: Failed" parsing
    error_code=$(echo "${line##*Code:}")
    echo "<pre>TX 1: Failed; code:${error_code}</pre>" >> $FILE_MESSAGE
    continue
  fi

  if grep -q "Failed with error" <<< "$line" && (( ATTEMP == 2 )); then
    ((ATTEMP++)) # skip next "Failed with error" parsing
    echo "<pre>${line}</pre>" >> $FILE_MESSAGE
    continue
  fi

  if grep -q "Autostake failed after" <<< "$line" ; then
    echo "${line}" >> $FILE_MESSAGE
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

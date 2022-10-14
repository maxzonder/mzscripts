#!/bin/bash
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# Load config
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

IFS="="
while read -r name value
do
  if [[ -n "${name}" && "${name}" != [[:blank:]#]* ]]; then
    eval ${name}="${value}"
  fi
done < $SCRIPT_DIR/server_status.ini

# FUNCTIONS

set_status() {
  # set yellow mark (warning sign emoji)
  status="\xE2\x9A\xA0"
  if [ "${result}" -gt $1 ]; then
    # set red mark (large red circle emoji)
    status="\xF0\x9F\x94\xB4"
  fi
  if [ "${result}" -lt $2 ]; then
    # set green (ok text) mark
    status="OK" 
  fi
}

fill_mount_line() {
  output_line+=$(awk -v pattern="$1" -F '[[:space:]]+' '$1 == pattern {print $2 "," $4 ","}' $SCRIPT_DIR/server_status_df_query.txt)
  result=$(awk -v pattern="$1" -F '[[:space:]]+' '$1 == pattern {print $5}' $SCRIPT_DIR/server_status_df_query.txt | sed 's/.$//')
  set_status $STORAGE_TRESHOLD_RED $STORAGE_TRESHOLD_YELLOW;
  output_line+="${result}%,${status}"$'\n'
}

# START
if [[ -n "${DRIVES}" ]]; then
  SERVER_INFO=${SERVER_INFO}$'\n\n'
fi

# Disk Storage 
IFS=" " read -a mountsArray <<< $MOUNTS
IFS=" " read -a mountsNamesArray <<< $MOUNTS_NAMES
df -h --total > $SCRIPT_DIR/server_status_df_query.txt

 output_line='MOUNT,SIZE,FREE,USED,STATUS'$'\n' 
output_line+='-----,----,----,----,------'$'\n' 
name_index=0;
for mount in ${mountsArray[@]}; do
  output_line+="${mountsNamesArray[$i]},"
  fill_mount_line ${mount}
  ((i=i+1))
done
output_line+='-----,----,----,----,------'$'\n' 
output_line+="Total,"
fill_mount_line "total"
output_storage=$(echo "$output_line" | column -s "," -t)

# SMART Status
if [[ -n "${DRIVES}" ]]; then
  IFS=" " read -a drivesArray <<< $DRIVES
  for i in ${!drivesArray[@]}; do
    smartctl -a ${drivesArray[$i]} > $SCRIPT_DIR/server_status_smart_query_drive${i}.txt
  done
  output_smart=""
  for i in ${!drivesArray[@]}; do  
    output_smart+=$((i+1))". "
    output_smart+=$(awk -F '[[:space:]][[:space:]]+' '$1 == "Model Number:" {print $2}' $SCRIPT_DIR/server_status_smart_query_drive${i}.txt)$'\n'
    output_smart+="   ${drivesArray[$i]}"$'\n'
    result=$(awk -F '[[:space:]][[:space:]]+' '$1 == "Percentage Used:" {print $2}' $SCRIPT_DIR/server_status_smart_query_drive${i}.txt | sed 's/.$//') 
    set_status $SMART_TRESHOLD_RED $SMART_TRESHOLD_YELLOW;
    output_smart+="   Percentage Used: ${result}% - $status"$'\n'
    errors=$(awk -F '[[:space:]][[:space:]]+' '$1 == "Error Information Log Entries:" {print $2}' $SCRIPT_DIR/server_status_smart_query_drive${i}.txt) 
    status="OK"
    if [ "${errors}" -gt 0 ]; then
      # set red mark (cross mark emoji)
      status="\xE2\x9D\x8C"
    fi
    output_smart+="   Error Entries:   ${errors} - $status"$'\n'    
    data_written=$(grep "Data Units Written:" $SCRIPT_DIR/server_status_smart_query_drive${i}.txt) 
    amount=$(echo "${data_written#*[}" | sed 's/.$//')
    output_smart+="   Data Written: ${amount}"$'\n\n'
  done
else  
  output_smart="Disabled"$'\n\n'
fi

# Memory usage
total_memory=$(expr $(free -m | awk '/^Mem:/{print $2}') / 1024)
avail_memory=$(awk -v low=$(grep low /proc/zoneinfo | awk '{k+=$2}END{print k}') '{a[$1]=$2}END{print a["MemFree:"]+a["Active(file):"]+a["Inactive(file):"]+a["SReclaimable:"]-(12*low);}' /proc/meminfo) 
avail_memory=$(expr $avail_memory / 1048576)
used_memory=$(($total_memory - $avail_memory))
result=$(awk -v t1="$used_memory" -v t2="$total_memory" 'BEGIN { printf "%.0f", (t1/t2)*100 }')
set_status $MEMORY_TRESHOLD_RED $MEMORY_TRESHOLD_YELLOW;
output_memory="${used_memory} GB / ${total_memory} GB | Used: ${result}% - ${status}"

# CPU Usage
values=""
for (( counts=1; counts<=10; counts++ )); do
  values+=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')$'\n'
  sleep 1 
done
cpu_usage=$(echo "$values" | awk -v counts=$counts '{ total += $1 } END { printf "%.2f", total/counts }')
result=$(echo "${cpu_usage}" | awk '{print int($1+0.5)}')
set_status $CPU_TRESHOLD_RED $CPU_TRESHOLD_YELLOW;
output_cpu="${cpu_usage}% - ${status}"

# Send Message
message=$(echo -e "<b>${SERVER_NAME}</b> | $(date +'%Y-%m-%d  %H:%M:%S')\n\n${SERVER_INFO}<b>Disk Space</b>\n\n<pre>${output_storage}</pre>\n\n<b>SMART Status</b>\n\n<pre>${output_smart}</pre><b>Memory</b>\n<pre>$output_memory</pre>\n\n<b>CPU</b>\n<pre>$output_cpu</pre>")

if [ -n "${TG_TOKEN}" ]; then
  curl -s --data "text=${message}" --data "chat_id=${TG_CHAT_ID}" --data "parse_mode=html" 'https://api.telegram.org/bot'${TG_TOKEN}'/sendMessage' > /dev/null
fi

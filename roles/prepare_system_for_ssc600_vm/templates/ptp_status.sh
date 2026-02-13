#!/bin/bash
PTP_STATUS_FILE="$PTP_STATUS_FOLDER/ptp_status"
test -d "$PTP_STATUS_FOLDER" || mkdir -p "$PTP_STATUS_FOLDER"

while true
do
  socket=${PTP4L_SOCKET_PATH//<num>/0}
  while read -r line
  do
    master=${line:2:1}
    if [ "$master" == "*" ]; then
      ptpnum=$(echo "$line" | cut -d',' -f3 -)
      ptpnum=${ptpnum:3:1}
      socket=${PTP4L_SOCKET_PATH//<num>/$ptpnum}
      break
    fi
  done < <(chronyc -c sources)

  pmc -s "$socket" -b 0 -u "GET TIME_STATUS_NP" "GET PORT_DATA_SET" "GET PARENT_DATA_SET" > "$PTP_STATUS_FILE"
  sleep 1
done
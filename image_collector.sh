#!/usr/bin/bash

echo image_collector.sh started !! > /dev/kmsg

# variables

DATE=$(date +%b-%d-%Y_%HH%MM)
IP=$(hostname -f | column -t -s "." | awk '{print $1}')" - "$(ip -4 -br a | grep -i "eth0\|vmbr0" | awk '{print $3}' | column -t -s "/" | awk '{print $1}')
IMAGE_NAME=$(echo $image_name)

share_path="/mnt/share"
images_backup_folder="/IMAGES_BACKUP"
images_backup_path=$(echo $share_path$images_backup_folder)
image_name=$(echo /$(date +%b-%d-%Y_%HH%MM)_$(echo $IP)"_copy.img.gz")

JSON_SUCCESS=$(echo '{ "timestamp": "'"$DATE"'", "source_ip": "'"$IP"'", "country": "BACKUP SUCCESSFUL" }')
JSON_FAIL=$(echo '{ "timestamp": "'"$DATE"'", "source_ip": "'"$IP"'", "country": "BACKUP FAILED" }')

# find the boot disk
v1=$(df /boot | grep -Eo '/dev/[^ ]+')
v2=${v1::-2}

# create the image, compress it and redirect it to the share
cmd2='dd if=$v2 iflag=fullblock bs=4M status=progress | gzip > "$images_backup_path$image_name"'

eval "$cmd2"

# check for errors
status2=$?

if [ $status2 -eq 0 ];
  then
    echo "Exit code: $status - image_collector.sh succesfully finished !!" > /dev/kmsg
    curl -sS -X POST -H "Content-Type: application/json" -d "$(echo $JSON_SUCCESS)" "https://x.matanga.com.ar/post"
  else
    echo "Exit code: $status - image_collector.sh failed - ERROR: problem creating the image." > /dev/kmsg
    curl -sS -X POST -H "Content-Type: application/json" -d "$(echo $JSON_FAIL)" "https://x.matanga.com.ar/post"
fi

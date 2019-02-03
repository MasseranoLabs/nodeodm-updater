#!/bin/bash 

if [ ! -e "$1" ]; then
    echo "Usage: $0 servers.txt"
    exit 1
fi

list="$1"

while read ssh_target; do
  if [ "$ssh_target" != "" ]; then
    echo "Updating $ssh_target..."
    ssh $ssh_target "nohup ./update.sh  > /dev/null 2>&1 &"
  fi
done <$list
#!/bin/bash 

if [ ! -e "$1" ]; then
    echo "Usage: $0 servers.txt"
    exit 1
fi

while read p; do
  parts=(${p//|/ })
  ssh_target=${parts[0]}
  info_url=${parts[1]}
  
  echo "Updating $ssh_target..."
  tmux -c "while [ \"$(curl -f -s \"$info_url\" | jq '.taskQueueCount')\" != \"0\" ]; do sleep 2; done; ./update.sh" &
done <$1
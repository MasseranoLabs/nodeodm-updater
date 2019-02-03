#!/bin/bash 

COPY_UPDATE_SCRIPT=NO

# Parse args for overrides
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --copy)
    export COPY_UPDATE_SCRIPT=YES
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameter


if [ ! -e "$1" ]; then
    echo "Usage: $0 servers.txt [--copy]"
    exit 1
fi

list="$1"

while read ssh_target; do
  if [ "$ssh_target" != "" ]; then

    if [ "$COPY_UPDATE_SCRIPT" = "YES" ]; then
        echo "Copying update script to $ssh_target..."
        scp ./update.sh $ssh_target:~
    else
        echo "Updating $ssh_target..."
        ssh $ssh_target "nohup ./update.sh  > /dev/null 2>&1 &"
    end
  fi
done <$list
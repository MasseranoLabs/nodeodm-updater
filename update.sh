#!/bin/bash 

hash jq 2>/dev/null || jq_not_found=true 
if [[ $jq_not_found ]]; then
    echo "jq not found, installing..."
    sudo apt install -y jq
fi

hash curl 2>/dev/null || curl_not_found=true 
if [[ $curl_not_found ]]; then
    echo "curl not found, installing..."
    sudo apt install -y curl
fi

hash docker 2>/dev/null || docker_not_found=true 
if [[ $docker_not_found ]]; then
    echo "docker not found, exiting..."
    exit 1
fi

if [ -e node.config ];  then
    source node.config
fi

if [ -z "$PORT" ]; then
    PORT=3000
fi

if [ -z "$MAX_IMAGES" ]; then
    echo "MAX_IMAGES is not defined"
    exit 1
fi

if [ -z "$S3_ACCESS" ]; then
    echo "S3_ACCESS is not defined"
    exit 1
fi

if [ -z "$S3_SECRET" ]; then
    echo "S3_SECRET is not defined"
    exit 1
fi

if [ -z "$S3_ENDPOINT" ]; then
    echo "S3_ENDPOINT is not defined"
    exit 1
fi

if [ -z "$S3_BUCKET" ]; then
    echo "S3_BUCKET is not defined"
    exit 1
fi

if [ -z "$WEBHOOK" ]; then
    echo "WEBHOOK is not defined"
    exit 1
fi

if [ -z "$QUEUE_SIZE" ]; then
    QUEUE_SIZE="2"
fi

if [ -z "$IMAGE" ]; then
    IMAGE="opendronemap/nodeodm"
fi

queue_cmd="--parallel_queue_processing $QUEUE_SIZE"

port_cmd="-p $PORT:3000"
if [ -z "$PUBLIC_NET" ]; then
    port_cmd="-p $(ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'):$PORT:3000"
fi

max_concurrency=$(($(nproc) / $QUEUE_SIZE))

if [ ! -z "$TOKEN" ]; then
    token=" --token $TOKEN "
fi

if [ ! -e node.config ]; then
echo "
PORT=$PORT
MAX_IMAGES=$MAX_IMAGES
S3_ACCESS=$S3_ACCESS
S3_SECRET=$S3_SECRET
S3_ENDPOINT=$S3_ENDPOINT
S3_BUCKET=$S3_BUCKET
WEBHOOK=$WEBHOOK
QUEUE_SIZE=$QUEUE_SIZE
TOKEN=$TOKEN
PUBLIC_NET=$PUBLIC_NET
IMAGE=$IMAGE
DOCKER_REPO=$DOCKER_REPO
DOCKER_USER=$DOCKER_USER
DOCKER_PASS=$DOCKER_PASS
" > node.config
fi

docker system prune --force

if [ ! -z "$DOCKER_USER" ]; then
	echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin $DOCKER_REPO
fi	

old_container_hash=$(docker ps -f "ancestor=$IMAGE" -aq)
docker pull $IMAGE

ip=$(docker ps --format "{{.Ports}}" | awk -F ":" 'NR==1 {print $1}')
if [ -z "$ip" ]; then
    ip="localhost"
fi

if [ -z "$FORCE" ]; then
    info_url=http://$ip:$PORT/info?token=$TOKEN
    if [ ! -z $(curl -f -s $info_url) ]; then
        while [ "$(curl -f -s $info_url | jq '.taskQueueCount')" != "0" ]; do 
            sleep 5; 
        done;
    fi
fi

docker stop $old_container_hash
docker rm $old_container_hash
docker run -d $port_cmd --restart always -v $(pwd)/data:/var/www/data $IMAGE --max_images $MAX_IMAGES --s3_access_key $S3_ACCESS --s3_secret_key $S3_SECRET --s3_endpoint $S3_ENDPOINT --s3_bucket $S3_BUCKET --webhook $WEBHOOK --max_concurrency $max_concurrency $queue_cmd $token --cleanup_tasks_after 1440 --max_runtime 5760

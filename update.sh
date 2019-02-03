#!/bin/bash 

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

max_concurrency=$(expr $(nproc) / $QUEUE_SIZE)

if [ ! -z "$TOKEN" ]; then
    $token=" --token $TOKEN "
fi

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
" > node.config

info_url=http://localhost:$PORT/info?token=$TOKEN
if [ ! -z $(curl -f -s $info_url) ];
    while [ "$(curl -f -s $info_url | jq '.taskQueueCount')" != "0" ]; do 
        sleep 5; 
    done;
fi

docker pull opendronemap/nodeodm
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker run -d -p $PORT:3000 --restart always -v $(pwd)/data:/var/www/data opendronemap/nodeodm --max_images $MAX_IMAGES --s3_access_key $S3_ACCESS --s3_secret_key $S3_SECRET --s3_endpoint $S3_ENDPOINT --s3_bucket $S3_BUCKET --webhook $WEBHOOK --max_concurrency $max_concurrency $token
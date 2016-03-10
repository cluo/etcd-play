#!/usr/bin/env bash
set -e

<<COMMENT
curl https://storage.googleapis.com/dister-scripts/stop_all_containers.sh | sh
curl https://storage.googleapis.com/play-etcd/etcd_play_web_20160311a.sh | sh
COMMENT

echo "Cleaning page cache..."
echo "echo 1 > /proc/sys/vm/drop_caches" | sudo sh

sudo docker ps

res=$(sudo docker ps -q)
if [ -n "${res}" ]; then
	echo stopping docker containers...
	sudo docker stop $res
else
	echo no docker containers to stop...
fi

res=$(sudo docker ps -q)
if [ -n "${res}" ]; then
	echo killing docker containers...
	sudo docker kill $res
else
	echo no docker containers to kill...
fi

res=$(sudo docker ps -a -q)
if [ -n "${res}" ]; then
	echo removing docker containers...
	sudo docker rm --force $res
else
	echo no docker containers to remove...
fi

sudo docker ps

sudo docker pull quay.io/coreos/etcd-play:latest

sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8000;

mkdir -p $HOME/logs
sudo docker pull quay.io/coreos/etcd-play:latest
AGENT_RPC_ENDPOINTS='10.128.0.2:9027,10.128.0.3:9027,10.128.0.4:9027,10.128.0.5:9027,10.128.0.6:9027'
nohup sudo docker run --net=host -p 8000:8000 quay.io/coreos/etcd-play:latest /go/bin/etcd-play web --port :8000 --keep-alive --linux-auto-port=false --production --remote --agent-endpoints="$(echo $AGENT_RPC_ENDPOINTS)" > $HOME/logs/play.log 2>&1 &

sudo docker ps

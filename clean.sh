set +e
docker compose down

docker ps -a |grep ago |awk '{print $1}'|xargs docker rm -f
#docker images |grep ago |awk '{print $3}'|xargs docker rmi -f
docker system prune --volumes -f
rm -rf /var/lib/containerd
rm -rf /var/lib/docker/volumes/trino*
systemctl stop docker
systmctl stop docker.socket
systemctl start docker
docker system prune --volumes -f

set -e

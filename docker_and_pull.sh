#snap install docker -y
bash docker_engine_ubuntu.sh
cat docker-compose.yml |grep -v '#'|grep image|awk '{print "docker pull ",$2}' >pull_image.sh

bash pull_image.sh

#!/bin/bash
set -xe

# --------- Basic packages ----------
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# --------- Install Docker ----------
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io

# Ensure docker starts
systemctl enable docker
systemctl start docker

# add ubuntu user to docker group (if you SSH as ubuntu)
usermod -aG docker ubuntu || true

# --------- ECS config (register to cluster) ----------
mkdir -p /etc/ecs /var/log/ecs /var/lib/ecs/data
cat > /etc/ecs/ecs.config <<ECSCONF
ECS_CLUSTER=${cluster_name}
ECS_AVAILABLE_LOGGING_DRIVERS=["awslogs","json-file"]
ECS_ENABLE_TASK_ENI=true
ECS_LOGLEVEL=info
ECS_DATADIR=/var/lib/ecs/data
ECS_LOGFILE=/var/log/ecs/ecs-agent.log
ECS_CHECKPOINT=true
ECS_ENABLE_CONTAINER_METADATA=true
ECS_ENABLE_EXEC=true
ECSCONF

chown -R root:root /etc/ecs /var/log/ecs /var/lib/ecs/data
chmod 600 /etc/ecs/ecs.config

# --------- systemd unit to run ECS agent as a docker container ----------
cat > /etc/systemd/system/amazon-ecs.service <<'SERVICE'
[Unit]
Description=Amazon ECS Agent
Requires=docker.service
After=docker.service

[Service]
Restart=always
RestartSec=5
# remove existing container if present, pull latest image, then run in foreground (so systemd manages it)
ExecStartPre=-/usr/bin/docker rm -f ecs-agent
ExecStartPre=/usr/bin/docker pull amazon/amazon-ecs-agent:latest
ExecStart=/usr/bin/docker run --name ecs-agent --env-file /etc/ecs/ecs.config --volume /var/run/docker.sock:/var/run/docker.sock --volume /var/log/ecs:/log --volume /var/lib/ecs/data:/data --net host amazon/amazon-ecs-agent:latest
ExecStop=/usr/bin/docker stop ecs-agent
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
SERVICE

# enable and start the service
systemctl daemon-reload
systemctl enable amazon-ecs
systemctl start amazon-ecs

# simple health check loop (optional; this writes a status file)
until docker ps --filter name=ecs-agent --format '{{.Names}}' | grep -q ecs-agent; do
  sleep 2
done
echo "ecs-agent started" > /var/log/ecs/agent-ready

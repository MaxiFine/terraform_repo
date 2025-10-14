# End of Terraform file


# -----------------------------------------------------------------------------
# ALSO ADD A FILE named "ecs.sh.tpl" in the same Terraform module folder with the
# exact contents provided below (this is the user-data template referenced by
# templatefile() above). Save it as ecs.sh.tpl next to this Terraform file.
# -----------------------------------------------------------------------------


# ecs.sh.tpl content (start)


#<-- BEGIN ecs.sh.tpl -->
#!/bin/bash
set -xe


# Basic packages
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release


# Install Docker (ECS-optimized AMI typically already includes Docker; this is safe)
if ! command -v docker >/dev/null 2>&1; then
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - || true
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >/etc/apt/sources.list.d/docker.list || true
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io || true
fi


systemctl enable docker || true
systemctl start docker || true


# create ecs config using injected cluster_name
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


# Run the ECS agent as a docker container managed by systemd
cat > /etc/systemd/system/amazon-ecs.service <<'SERVICE'
[Unit]
Description=Amazon ECS Agent
Requires=docker.service
After=docker.service


[Service]
Restart=always
#<-- END ecs.sh.tpl -->

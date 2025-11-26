#!/bin/bash
#############################################
# User Data Script for SSM-Enabled EC2 Instance
# Purpose: Bootstrap SSM agent, install monitoring tools,
#          configure CloudWatch agent, and set up utilities
#############################################

set -e  # Exit on any error

# Update system packages
echo "=== Updating system packages ==="
apt-get update -y
apt-get upgrade -y

# Install SSM Agent (Ubuntu 22.04 has it, but ensure latest version)
echo "=== Installing/Updating SSM Agent ==="
snap refresh amazon-ssm-agent --classic || snap install amazon-ssm-agent --classic

# Start and enable SSM Agent
echo "=== Starting SSM Agent ==="
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service --no-pager

# Install CloudWatch Agent for monitoring
echo "=== Installing CloudWatch Agent ==="
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Install useful monitoring and debugging tools
echo "=== Installing monitoring and utility tools ==="
apt-get install -y \
    htop \
    iotop \
    sysstat \
    net-tools \
    curl \
    wget \
    jq \
    unzip \
    git \
    vim \
    dnsutils \
    telnet \
    netcat \
    tcpdump \
    stress-ng

# Install AWS CLI v2
echo "=== Installing AWS CLI v2 ==="
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install
    rm -rf awscliv2.zip aws/
fi

# Configure CloudWatch agent with basic config
echo "=== Configuring CloudWatch Agent ==="
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json << 'EOF'
{
  "metrics": {
    "namespace": "SSM-PrivateInstance",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          },
          "cpu_usage_iowait"
        ],
        "totalcpu": false,
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/amazon/ssm/amazon-ssm-agent.log",
            "log_group_name": "/aws/ssm/private-instance",
            "log_stream_name": "{instance_id}/ssm-agent",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/aws/ssm/private-instance",
            "log_stream_name": "{instance_id}/syslog",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch Agent (will auto-start on future boots)
echo "=== Starting CloudWatch Agent ==="
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Create a simple system info script
echo "=== Creating system info script ==="
cat > /usr/local/bin/sysinfo << 'EOF'
#!/bin/bash
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Private IP: $(hostname -I | awk '{print $1}')"
echo "Instance ID: $(ec2-metadata --instance-id | cut -d ' ' -f 2)"
echo "Availability Zone: $(ec2-metadata --availability-zone | cut -d ' ' -f 2)"
echo "AMI ID: $(ec2-metadata --ami-id | cut -d ' ' -f 2)"
echo ""
echo "=== SSM Agent Status ==="
systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service --no-pager | grep Active
echo ""
echo "=== Resource Usage ==="
echo "CPU: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
echo "Memory: $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')"
echo "Disk: $(df -h / | awk 'NR==2{print $5}')"
echo ""
echo "=== Network Connectivity ==="
echo "SSM Endpoint: $(curl -s -o /dev/null -w "%{http_code}" https://ssm.eu-west-1.amazonaws.com)"
echo "Internet: $(curl -s -o /dev/null -w "%{http_code}" https://www.google.com)"
EOF

chmod +x /usr/local/bin/sysinfo

# Create SSM connection test script
echo "=== Creating SSM test script ==="
cat > /usr/local/bin/ssm-test << 'EOF'
#!/bin/bash
echo "=== Testing SSM Connectivity ==="
echo ""
echo "1. SSM Agent Status:"
systemctl is-active snap.amazon-ssm-agent.amazon-ssm-agent.service
echo ""
echo "2. Instance Registration:"
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d ' ' -f 2)
aws ssm describe-instance-information \
    --instance-information-filter-list key=InstanceIds,valueSet=$INSTANCE_ID \
    --region eu-west-1 \
    --query "InstanceInformationList[0].[PingStatus,LastPingDateTime,AgentVersion]" \
    --output text 2>/dev/null || echo "Not registered or no permissions"
echo ""
echo "3. VPC Endpoint Connectivity:"
for endpoint in ssm.eu-west-1.amazonaws.com ssmmessages.eu-west-1.amazonaws.com ec2messages.eu-west-1.amazonaws.com; do
    echo -n "$endpoint: "
    if timeout 5 bash -c "echo > /dev/tcp/${endpoint}/443" 2>/dev/null; then
        echo "✓ Reachable"
    else
        echo "✗ Unreachable"
    fi
done
EOF

chmod +x /usr/local/bin/ssm-test

# Create welcome message
cat > /etc/motd << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║          SSM-Enabled Private Instance (No Public IP)         ║
╚══════════════════════════════════════════════════════════════╝

Welcome! You're connected via AWS Systems Manager Session Manager.

Quick Commands:
  sysinfo       - Display system and SSM status
  ssm-test      - Test SSM connectivity and registration
  htop          - Interactive process viewer
  stress-ng     - System stress testing tool

Monitoring:
  - CloudWatch metrics: SSM-PrivateInstance namespace
  - CloudWatch logs: /aws/ssm/private-instance

This instance has NO public IP and NO SSH keys configured.
All access is via IAM-authenticated Session Manager.

EOF

# Configure automatic security updates
echo "=== Enabling automatic security updates ==="
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Set timezone
echo "=== Setting timezone to UTC ==="
timedatectl set-timezone UTC

# Final verification
echo "=== Bootstrap Complete ==="
echo "SSM Agent: $(systemctl is-active snap.amazon-ssm-agent.amazon-ssm-agent.service)"
echo "CloudWatch Agent: $(systemctl is-active amazon-cloudwatch-agent.service)"
echo "Instance will register with SSM within 2-3 minutes"

# Log completion to CloudWatch (if agent is running)
echo "$(date): User data script completed successfully" >> /var/log/user-data.log

echo "=== User Data Script Finished ==="

#!/bin/bash
# NAT Instance Testing Script
# This script helps verify the NAT instance is working correctly

echo "======================================"
echo "NAT Instance Functionality Test"
echo "======================================"
echo ""

# Get instance IDs from Terraform outputs
echo "Step 1: Getting instance IDs..."
NAT_INSTANCE_ID=$(terraform output -raw nat_instance_id 2>/dev/null)
PRIVATE_INSTANCE_ID=$(terraform output -raw private_test_instance_id 2>/dev/null)
NAT_EIP=$(terraform output -raw nat_instance_eip 2>/dev/null)

if [ -z "$NAT_INSTANCE_ID" ] || [ -z "$PRIVATE_INSTANCE_ID" ]; then
    echo "ERROR: Could not get instance IDs from Terraform outputs."
    echo "Make sure you've run 'terraform apply' successfully."
    exit 1
fi

echo "✓ NAT Instance ID: $NAT_INSTANCE_ID"
echo "✓ Private Test Instance ID: $PRIVATE_INSTANCE_ID"
echo "✓ NAT Elastic IP: $NAT_EIP"
echo ""

# Check instance states
echo "Step 2: Checking instance states..."
NAT_STATE=$(aws ec2 describe-instances --instance-ids "$NAT_INSTANCE_ID" --query 'Reservations[0].Instances[0].State.Name' --output text)
PRIVATE_STATE=$(aws ec2 describe-instances --instance-ids "$PRIVATE_INSTANCE_ID" --query 'Reservations[0].Instances[0].State.Name' --output text)

echo "NAT Instance State: $NAT_STATE"
echo "Private Instance State: $PRIVATE_STATE"

if [ "$NAT_STATE" != "running" ] || [ "$PRIVATE_STATE" != "running" ]; then
    echo "WARNING: One or both instances are not running. Please start them first."
    exit 1
fi
echo ""

# Check NAT instance configuration
echo "Step 3: Verifying NAT instance configuration..."
aws ec2 describe-instances --instance-ids "$NAT_INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].{SourceDestCheck:SourceDestCheck,PublicIp:PublicIpAddress,PrivateIp:PrivateIpAddress}' \
  --output table
echo ""

# Check route tables
echo "Step 4: Verifying route table configuration..."
NAT_ENI=$(aws ec2 describe-instances --instance-ids "$NAT_INSTANCE_ID" --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' --output text)
echo "NAT Instance ENI: $NAT_ENI"

aws ec2 describe-route-tables \
  --filters "Name=route.destination-cidr-block,Values=0.0.0.0/0" "Name=route.network-interface-id,Values=$NAT_ENI" \
  --query 'RouteTables[].{RouteTableId:RouteTableId,Route:Routes[?DestinationCidrBlock==`0.0.0.0/0`]}' \
  --output table
echo ""

# Wait for SSM agent
echo "Step 5: Waiting for SSM agents to be ready (max 30 seconds)..."
for i in {1..6}; do
    NAT_SSM=$(aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$NAT_INSTANCE_ID" --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null)
    PRIVATE_SSM=$(aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$PRIVATE_INSTANCE_ID" --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null)
    
    if [ "$NAT_SSM" = "Online" ] && [ "$PRIVATE_SSM" = "Online" ]; then
        echo "✓ Both instances are SSM-ready"
        break
    fi
    
    echo "  Waiting... ($i/6)"
    sleep 5
done
echo ""

# Test NAT instance
echo "======================================"
echo "Testing NAT Instance"
echo "======================================"
echo ""
echo "Checking IP forwarding and iptables rules..."
echo ""

aws ssm send-command \
    --instance-ids "$NAT_INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=[
        "echo NAT Instance Configuration Check:",
        "echo ================================",
        "echo",
        "echo 1. IP Forwarding Status:",
        "sudo sysctl net.ipv4.ip_forward",
        "echo",
        "echo 2. Network Interfaces:",
        "ip link show | grep -E \"^[0-9]+:|state\"",
        "echo",
        "echo 3. NAT iptables rules:",
        "sudo iptables -t nat -S POSTROUTING",
        "echo",
        "echo 4. FORWARD chain rules:",
        "sudo iptables -S FORWARD",
        "echo",
        "echo 5. Internet connectivity test:",
        "curl -s --max-time 5 https://checkip.amazonaws.com || echo Failed to reach internet"
    ]' \
    --output text \
    --query 'Command.CommandId' > /tmp/nat-test-cmd.txt

NAT_CMD_ID=$(cat /tmp/nat-test-cmd.txt)
echo "Command ID: $NAT_CMD_ID"
echo "Waiting for command to complete..."
sleep 8

echo ""
echo "NAT Instance Test Results:"
echo "================================"
aws ssm get-command-invocation \
    --command-id "$NAT_CMD_ID" \
    --instance-id "$NAT_INSTANCE_ID" \
    --query 'StandardOutputContent' \
    --output text

echo ""
echo ""

# Test private instance
echo "======================================"
echo "Testing Private Instance (via NAT)"
echo "======================================"
echo ""
echo "Testing internet connectivity through NAT..."
echo ""

aws ssm send-command \
    --instance-ids "$PRIVATE_INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=[
        \"echo Private Instance NAT Test:\",
        \"echo ================================\",
        \"echo\",
        \"echo 1. Checking default route:\",
        \"ip route | grep default\",
        \"echo\",
        \"echo 2. Testing internet connectivity:\",
        \"curl -s --max-time 10 https://checkip.amazonaws.com || echo Failed to reach internet\",
        \"echo\",
        \"echo 3. Expected IP: $NAT_EIP\",
        \"echo\",
        \"echo 4. DNS resolution test:\",
        \"nslookup aws.amazon.com | head -5\",
        \"echo\",
        \"echo 5. HTTP test:\",
        \"curl -I -s --max-time 10 https://example.com | head -3\",
        \"echo\",
        \"echo 6. Package manager test:\",
        \"sudo dnf check-update --quiet | head -5 || echo Repo access successful\"
    ]" \
    --output text \
    --query 'Command.CommandId' > /tmp/private-test-cmd.txt

PRIVATE_CMD_ID=$(cat /tmp/private-test-cmd.txt)
echo "Command ID: $PRIVATE_CMD_ID"
echo "Waiting for command to complete..."
sleep 10

echo ""
echo "Private Instance Test Results:"
echo "================================"
aws ssm get-command-invocation \
    --command-id "$PRIVATE_CMD_ID" \
    --instance-id "$PRIVATE_INSTANCE_ID" \
    --query 'StandardOutputContent' \
    --output text

echo ""
echo "======================================"
echo "Test Complete!"
echo "======================================"
echo ""
echo "Summary:"
echo "--------"
echo "If the private instance shows IP = $NAT_EIP, NAT is working correctly!"
echo ""
echo "To manually connect to instances:"
echo "  NAT Instance:     aws ssm start-session --target $NAT_INSTANCE_ID"
echo "  Private Instance: aws ssm start-session --target $PRIVATE_INSTANCE_ID"
echo ""

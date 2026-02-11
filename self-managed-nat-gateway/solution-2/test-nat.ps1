# NAT Instance Testing Script (PowerShell)
# This script helps verify the NAT instance is working correctly

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "NAT Instance Functionality Test" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Get instance IDs from Terraform outputs
Write-Host "Step 1: Getting instance IDs..." -ForegroundColor Yellow
$NAT_INSTANCE_ID = terraform output -raw nat_instance_id 2>$null
$PRIVATE_INSTANCE_ID = terraform output -raw private_test_instance_id 2>$null
$NAT_EIP = terraform output -raw nat_instance_eip 2>$null

if (-not $NAT_INSTANCE_ID -or -not $PRIVATE_INSTANCE_ID) {
    Write-Host "ERROR: Could not get instance IDs from Terraform outputs." -ForegroundColor Red
    Write-Host "Make sure you've run 'terraform apply' successfully." -ForegroundColor Red
    exit 1
}

Write-Host "✓ NAT Instance ID: $NAT_INSTANCE_ID" -ForegroundColor Green
Write-Host "✓ Private Test Instance ID: $PRIVATE_INSTANCE_ID" -ForegroundColor Green
Write-Host "✓ NAT Elastic IP: $NAT_EIP" -ForegroundColor Green
Write-Host ""

# Check instance states
Write-Host "Step 2: Checking instance states..." -ForegroundColor Yellow
$NAT_STATE = aws ec2 describe-instances --instance-ids $NAT_INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name' --output text
$PRIVATE_STATE = aws ec2 describe-instances --instance-ids $PRIVATE_INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name' --output text

Write-Host "NAT Instance State: $NAT_STATE"
Write-Host "Private Instance State: $PRIVATE_STATE"

if ($NAT_STATE -ne "running" -or $PRIVATE_STATE -ne "running") {
    Write-Host "WARNING: One or both instances are not running. Please start them first." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check NAT instance configuration
Write-Host "Step 3: Verifying NAT instance configuration..." -ForegroundColor Yellow
aws ec2 describe-instances --instance-ids $NAT_INSTANCE_ID `
  --query 'Reservations[0].Instances[0].{SourceDestCheck:SourceDestCheck,PublicIp:PublicIpAddress,PrivateIp:PrivateIpAddress}' `
  --output table
Write-Host ""

# Check route tables
Write-Host "Step 4: Verifying route table configuration..." -ForegroundColor Yellow
$NAT_ENI = aws ec2 describe-instances --instance-ids $NAT_INSTANCE_ID --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' --output text
Write-Host "NAT Instance ENI: $NAT_ENI"

aws ec2 describe-route-tables `
  --filters "Name=route.destination-cidr-block,Values=0.0.0.0/0" "Name=route.network-interface-id,Values=$NAT_ENI" `
  --query 'RouteTables[].{RouteTableId:RouteTableId,Route:Routes[?DestinationCidrBlock==`0.0.0.0/0`]}' `
  --output table
Write-Host ""

# Wait for SSM agent
Write-Host "Step 5: Waiting for SSM agents to be ready (max 30 seconds)..." -ForegroundColor Yellow
for ($i = 1; $i -le 6; $i++) {
    $NAT_SSM = aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$NAT_INSTANCE_ID" --query 'InstanceInformationList[0].PingStatus' --output text 2>$null
    $PRIVATE_SSM = aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$PRIVATE_INSTANCE_ID" --query 'InstanceInformationList[0].PingStatus' --output text 2>$null
    
    if ($NAT_SSM -eq "Online" -and $PRIVATE_SSM -eq "Online") {
        Write-Host "✓ Both instances are SSM-ready" -ForegroundColor Green
        break
    }
    
    Write-Host "  Waiting... ($i/6)"
    Start-Sleep -Seconds 5
}
Write-Host ""

# Test NAT instance
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Testing NAT Instance" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Checking IP forwarding and iptables rules..." -ForegroundColor Yellow
Write-Host ""

$NAT_CMD_ID = aws ssm send-command `
    --instance-ids $NAT_INSTANCE_ID `
    --document-name "AWS-RunShellScript" `
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
    ]' `
    --output text `
    --query 'Command.CommandId'

Write-Host "Command ID: $NAT_CMD_ID"
Write-Host "Waiting for command to complete..."
Start-Sleep -Seconds 8

Write-Host ""
Write-Host "NAT Instance Test Results:" -ForegroundColor Green
Write-Host "================================"
aws ssm get-command-invocation `
    --command-id $NAT_CMD_ID `
    --instance-id $NAT_INSTANCE_ID `
    --query 'StandardOutputContent' `
    --output text

Write-Host ""
Write-Host ""

# Test private instance
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Testing Private Instance (via NAT)" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testing internet connectivity through NAT..." -ForegroundColor Yellow
Write-Host ""

$PRIVATE_CMD_ID = aws ssm send-command `
    --instance-ids $PRIVATE_INSTANCE_ID `
    --document-name "AWS-RunShellScript" `
    --parameters "commands=[
        \`"echo Private Instance NAT Test:\`",
        \`"echo ================================\`",
        \`"echo\`",
        \`"echo 1. Checking default route:\`",
        \`"ip route | grep default\`",
        \`"echo\`",
        \`"echo 2. Testing internet connectivity:\`",
        \`"curl -s --max-time 10 https://checkip.amazonaws.com || echo Failed to reach internet\`",
        \`"echo\`",
        \`"echo 3. Expected IP: $NAT_EIP\`",
        \`"echo\`",
        \`"echo 4. DNS resolution test:\`",
        \`"nslookup aws.amazon.com | head -5\`",
        \`"echo\`",
        \`"echo 5. HTTP test:\`",
        \`"curl -I -s --max-time 10 https://example.com | head -3\`",
        \`"echo\`",
        \`"echo 6. Package manager test:\`",
        \`"sudo dnf check-update --quiet | head -5 || echo Repo access successful\`"
    ]" `
    --output text `
    --query 'Command.CommandId'

Write-Host "Command ID: $PRIVATE_CMD_ID"
Write-Host "Waiting for command to complete..."
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Private Instance Test Results:" -ForegroundColor Green
Write-Host "================================"
aws ssm get-command-invocation `
    --command-id $PRIVATE_CMD_ID `
    --instance-id $PRIVATE_INSTANCE_ID `
    --query 'StandardOutputContent' `
    --output text

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Test Complete!" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "--------"
Write-Host "If the private instance shows IP = $NAT_EIP, NAT is working correctly!" -ForegroundColor Green
Write-Host ""
Write-Host "To manually connect to instances:" -ForegroundColor Yellow
Write-Host "  NAT Instance:     aws ssm start-session --target $NAT_INSTANCE_ID" -ForegroundColor Cyan
Write-Host "  Private Instance: aws ssm start-session --target $PRIVATE_INSTANCE_ID" -ForegroundColor Cyan
Write-Host ""

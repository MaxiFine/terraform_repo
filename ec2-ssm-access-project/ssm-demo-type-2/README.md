# SSM Access to Private EC2 Instance

This project demonstrates how to access a private EC2 instance (without public IP) using AWS Systems Manager (SSM) Session Manager via VPC endpoints.

## Architecture

```
Private EC2 Instance (10.0.1.0/24)
         ↓
    SSM Agent
         ↓
VPC Interface Endpoints (HTTPS 443)
    - com.amazonaws.eu-west-1.ssm
    - com.amazonaws.eu-west-1.ssmmessages
    - com.amazonaws.eu-west-1.ec2messages
         ↓
    AWS SSM Service
```

## What's Configured

✅ **VPC & Networking**
- Private subnet (10.0.1.0/24) with no internet access
- Route table without NAT or IGW routes

✅ **VPC Endpoints (Interface)**
- SSM endpoints for private connectivity
- Private DNS enabled for seamless agent communication

✅ **IAM Role & Instance Profile**
- AmazonSSMManagedInstanceCore policy attached
- Assigned to EC2 instance for SSM permissions

✅ **Security Groups**
- Instance SG: Allows outbound HTTPS (443) to VPC endpoints
- Endpoint SG: Accepts HTTPS (443) from VPC CIDR

✅ **EC2 Instance**
- Ubuntu 22.04 LTS (latest)
- SSM agent pre-installed on Ubuntu AMIs
- No public IP address

## Prerequisites

- AWS CLI installed and configured
- Terraform 1.5+
- Session Manager plugin for AWS CLI ([installation guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html))

## Deployment

```powershell
# Navigate to project
cd ec2-ssm-access-project/ssm-demo-type-2

# Set AWS profile if needed
$env:AWS_PROFILE = "your-profile"

# Initialize and apply
terraform init
terraform plan
terraform apply
```

## Connect via SSM

After deployment (wait ~2-3 minutes for instance to register with SSM):

```powershell
# Get instance ID from outputs
terraform output instance_id

# Connect via Session Manager
aws ssm start-session --target <instance-id> --region eu-west-1

# Or use the command from output
terraform output -raw ssm_connection_command | Invoke-Expression
```

## Troubleshooting

### Instance not showing in SSM
```powershell
# Check if instance is registered with SSM
aws ssm describe-instance-information --region eu-west-1

# Check SSM agent status via CloudWatch Logs
# The agent logs to /var/log/amazon/ssm/amazon-ssm-agent.log on the instance
```

**Common causes:**
- Instance just started (wait 2-3 minutes)
- IAM instance profile not attached
- Security group blocking HTTPS to endpoints
- VPC endpoints not created correctly
- DNS resolution not working (check `enable_dns_hostnames = true` on VPC)

### Cannot connect via Session Manager
- Ensure Session Manager plugin is installed on your local machine
- Verify AWS CLI is authenticated
- Check IAM permissions for your user (needs `ssm:StartSession`)

### Manual verification steps
```powershell
# 1. Check VPC endpoints exist
aws ec2 describe-vpc-endpoints --region eu-west-1

# 2. Verify instance profile is attached
aws ec2 describe-instances --instance-ids <instance-id> --region eu-west-1 --query 'Reservations[0].Instances[0].IamInstanceProfile'

# 3. Check security group rules
aws ec2 describe-security-groups --group-ids <sg-id> --region eu-west-1
```

## Key Files

- `main.tf` - VPC, subnet, route table, and EC2 instance
- `ssm-configs.tf` - IAM role, instance profile, and policies
- `vpc-endpoint.tf` - VPC interface endpoints and security groups
- `variables.tf` - Region and AMI configuration
- `outputs.tf` - Instance ID and helpful commands

## Cost

- **VPC Endpoints**: ~$0.01/hour per endpoint × 3 = ~$0.03/hour (~$22/month)
- **EC2 t3.micro**: ~$0.0104/hour (~$7.50/month in eu-west-1)
- **Data transfer**: Minimal for SSM sessions

**Total**: ~$30/month if left running

💡 **Tip**: Destroy resources when not in use to avoid charges.

## Cleanup

```powershell
terraform destroy
```

## What You Learned

- ✅ Accessing private instances without bastion hosts
- ✅ VPC interface endpoints for AWS services
- ✅ IAM roles and instance profiles
- ✅ Security group configuration for service endpoints
- ✅ AWS Systems Manager Session Manager

## Next Steps

- Add S3 VPC endpoint for storing session logs
- Configure session logging to CloudWatch
- Add KMS encryption for session data
- Create multiple private instances with shared endpoints
- Add CloudWatch logs for SSM agent troubleshooting

---

**Region**: eu-west-1  
**SSM Agent**: Pre-installed on Ubuntu 22.04 AMIs  
**Connection method**: Session Manager (no SSH keys needed)

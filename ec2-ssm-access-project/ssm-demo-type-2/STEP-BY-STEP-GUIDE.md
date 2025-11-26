# Step-by-Step Guide: Access Private EC2 via AWS SSM

This is a complete, beginner-friendly guide to set up and access a private EC2 instance using AWS Systems Manager (no SSH, no bastion host needed!).

## 🎯 What You'll Build

A private EC2 instance in AWS that you can access through your browser or terminal using AWS Systems Manager - even though it has no public IP address!

## 📋 Prerequisites (Do This First!)

### 1. Install Required Software

**AWS CLI**
```powershell
# Download from: https://aws.amazon.com/cli/
# Or install via winget:
winget install Amazon.AWSCLI

# Verify installation:
aws --version
# Should show: aws-cli/2.x.x or higher
```

**Session Manager Plugin**
```powershell
# Download installer from:
# https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# For Windows, download and run: SessionManagerPluginSetup.exe

# Verify installation:
session-manager-plugin
# Should show: The Session Manager plugin is installed successfully!
```

**Terraform**
```powershell
# Download from: https://www.terraform.io/downloads
# Or install via chocolatey:
choco install terraform

# Verify installation:
terraform version
# Should show: Terraform v1.5.x or higher
```

### 2. Configure AWS Credentials

```powershell
# Option A: Configure a new profile
aws configure --profile awscc
# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: eu-west-1
# - Default output format: json

# Option B: If already configured, verify it works
aws sts get-caller-identity --profile awscc
# Should show your AWS account details
```

## 🚀 Step-by-Step Deployment

### Step 1: Download/Navigate to the Project

```powershell
# Navigate to the project folder
cd c:\Users\MaxwellAdomako\amalitech\learning-projects\terraform_repo\ec2-ssm-access-project\ssm-demo-type-2
```

### Step 2: Review the Configuration Files

You don't need to understand everything, but here's what each file does:

- **main.tf** - Creates VPC, subnet, and EC2 instance
- **ssm-configs.tf** - Sets up IAM permissions for SSM
- **vpc-endpoint.tf** - Creates private AWS service endpoints
- **variables.tf** - Configurable settings (region, AMI)
- **outputs.tf** - Shows useful information after deployment

### Step 3: Set Your AWS Profile

```powershell
# Set the AWS profile to use
$env:AWS_PROFILE = "awscc"

# Verify you're using the right account
aws sts get-caller-identity
# Check the "Account" number matches your intended AWS account
```

### Step 4: Initialize Terraform

```powershell
# Download required Terraform providers
terraform init

# You should see: "Terraform has been successfully initialized!"
```

### Step 5: Preview What Will Be Created

```powershell
# See what Terraform will create (dry run)
terraform plan

# Review the output - you should see it will create:
# - 1 VPC
# - 1 Subnet
# - 1 Route table
# - 1 EC2 instance
# - 3 VPC endpoints (for SSM)
# - 2 Security groups
# - 1 IAM role and instance profile
```

### Step 6: Create the Infrastructure

```powershell
# Create everything in AWS
terraform apply

# Type "yes" when prompted
# Wait 2-3 minutes for completion
```

You'll see output like this:
```
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

instance_id = "i-0123456789abcdef0"
ssm_connection_command = "aws ssm start-session --target i-0123456789abcdef0 --region eu-west-1"
```

### Step 7: Wait for SSM Agent to Register

```powershell
# The EC2 instance needs time to register with SSM
# Wait 2-3 minutes, then check:

aws ssm describe-instance-information --region eu-west-1

# You should see your instance listed with PingStatus: "Online"
```

### Step 8: Connect to Your Private Instance!

```powershell
# Get the connection command from Terraform
terraform output -raw ssm_connection_command

# Copy and run the command, OR run this:
$instanceId = terraform output -raw instance_id
aws ssm start-session --target $instanceId --region eu-west-1
```

**Success!** You should now see a terminal prompt like:
```
sh-5.1$
```

You're now inside your private EC2 instance! 🎉

### Step 9: Test Your Connection

Inside the SSM session, try these commands:

```bash
# Check you're on the private instance
hostname

# Check the private IP address
ip addr show

# Check internet connectivity works
curl -I https://www.google.com

# Exit the session
exit
```

## 🧹 Cleanup (Important!)

**When you're done testing**, destroy the resources to avoid charges:

```powershell
# Go back to the project directory
cd c:\Users\MaxwellAdomako\amalitech\learning-projects\terraform_repo\ec2-ssm-access-project\ssm-demo-type-2

# Destroy everything
terraform destroy

# Type "yes" when prompted
# Wait 2-3 minutes for completion
```

## ❓ Troubleshooting

### Problem: "terraform: command not found"
**Solution**: Terraform not installed or not in PATH. Reinstall and restart PowerShell.

### Problem: "Error: NoCredentialProviders"
**Solution**: AWS credentials not configured. Run `aws configure --profile awscc`

### Problem: "ExpiredToken" error
**Solution**: Your AWS session expired. Run `aws configure --profile awscc` again or refresh your SSO session.

### Problem: Instance not showing in SSM after 5+ minutes
```powershell
# Check if IAM role is attached
aws ec2 describe-instances --instance-ids <your-instance-id> --region eu-west-1 --query 'Reservations[0].Instances[0].IamInstanceProfile'

# Should show: { "Arn": "...", "Id": "..." }
# If null, the instance profile didn't attach correctly
```

**Solution**: Run `terraform apply` again to fix the configuration.

### Problem: "TargetNotConnected" when trying to connect
**Solution**: 
1. Wait longer (up to 5 minutes for first connection)
2. Check instance is running: `aws ec2 describe-instances --instance-ids <id> --region eu-west-1`
3. Verify VPC endpoints are available: `aws ec2 describe-vpc-endpoints --region eu-west-1`

### Problem: Session Manager plugin not found
```
SessionManagerPlugin is not found. Please refer to SessionManager Documentation here: http://docs.aws.amazon.com/console/systems-manager/session-manager-plugin-not-found
```

**Solution**: Install the Session Manager plugin (see Prerequisites section above), then restart PowerShell.

## 📊 What's Happening Behind the Scenes?

```
Your Computer
     ↓ (1) Run: aws ssm start-session
AWS SSM Service
     ↓ (2) Connect to VPC Endpoints
VPC Interface Endpoints (private)
     ↓ (3) Route to private instance
EC2 Instance (10.0.1.x)
     ↓ (4) SSM Agent sends session back
Your Terminal (secure shell!)
```

**Key Points:**
- ✅ No public IP needed on the instance
- ✅ No SSH keys to manage
- ✅ No bastion host to maintain
- ✅ All traffic stays within AWS network
- ✅ Full audit logging in CloudTrail

## 💰 Cost Estimate

If you leave this running 24/7:

| Resource | Cost (eu-west-1) |
|----------|------------------|
| VPC Endpoints (3) | ~$22/month |
| EC2 t3.micro | ~$7.50/month |
| **Total** | **~$30/month** |

**💡 Tip**: Destroy when not in use! The whole setup redeploys in 3 minutes.

## 🎓 What You Learned

- ✅ Creating private AWS infrastructure with Terraform
- ✅ Using VPC endpoints for private AWS service access
- ✅ IAM roles and instance profiles
- ✅ AWS Systems Manager Session Manager
- ✅ Accessing instances without SSH or bastion hosts

## 🔄 Quick Reference Commands

```powershell
# Set AWS profile
$env:AWS_PROFILE = "awscc"

# Navigate to project
cd c:\Users\MaxwellAdomako\amalitech\learning-projects\terraform_repo\ec2-ssm-access-project\ssm-demo-type-2

# Deploy
terraform init
terraform plan
terraform apply

# Connect
aws ssm start-session --target $(terraform output -raw instance_id) --region eu-west-1

# Cleanup
terraform destroy
```

## 📚 Next Steps

Once comfortable with this setup, try:

1. **Add CloudWatch Logs** - Log all SSM sessions
2. **Multiple Instances** - Share VPC endpoints across instances
3. **S3 Endpoint** - Access S3 from private instances
4. **Custom AMI** - Use your own AMI instead of Ubuntu
5. **Auto-scaling** - Use this pattern with ASG

## 🆘 Still Stuck?

Check the detailed README.md in this folder, or review:
- AWS Systems Manager docs: https://docs.aws.amazon.com/systems-manager/
- Terraform AWS provider docs: https://registry.terraform.io/providers/hashicorp/aws/

---

**Remember**: Always run `terraform destroy` when you're done to avoid unnecessary costs! 💰

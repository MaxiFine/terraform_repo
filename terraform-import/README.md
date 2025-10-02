# Terraform Import Example

This project demonstrates how to import existing AWS resources into Terraform state management. Specifically, it shows how to import an existing S3 bucket and manage it with Terraform.

## 📋 Overview

When you have existing AWS resources that weren't created with Terraform, you can use the `terraform import` command to bring them under Terraform management. This example walks through importing an S3 bucket.

## 🏗️ Architecture

This configuration manages:
- **S3 Bucket**: `mx-terraform-import-bucket`
- **Bucket Tags**: Name, Type, LiveBucket, test
- **Force Destroy**: Enabled for easy cleanup

## 📁 Project Structure

```
terraform-import/
├── main.tf           # Main Terraform configuration
├── terraform.tfstate # Terraform state file (after import)
└── README.md         # This documentation
```

## 🔧 Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed (v1.0+)
- [AWS CLI](https://aws.amazon.com/cli/) configured
- AWS credentials configured with appropriate permissions
- An existing S3 bucket to import

## ⚙️ Configuration

### Provider Configuration
- **AWS Provider**: Version ~> 5.0
- **Region**: us-east-1
- **Profile**: awscc (set via environment variable)

### Resource Configuration
```terraform
resource "aws_s3_bucket" "terraform_import" {
  bucket        = "mx-terraform-import-bucket"
  force_destroy = true
  
  tags = {
    Name       = "mx-terraform-import-bucket" 
    Type       = "Import"
    LiveBucket = "mx-terraform-import-bucket"
    test       = "import"
  }
}
```

## 🚀 Usage

### Step 1: Initialize Terraform
```powershell
terraform init
```

### Step 2: Verify the bucket exists
```powershell
aws --profile awscc s3 ls | findstr mx-terraform-import-bucket
```

### Step 3: Check bucket region
```powershell
aws --profile awscc s3api get-bucket-location --bucket mx-terraform-import-bucket
```

### Step 4: Set AWS Profile
```powershell
$env:AWS_PROFILE="awscc"
```

### Step 5: Import the existing bucket
```powershell
terraform import aws_s3_bucket.terraform_import mx-terraform-import-bucket
```

### Step 6: Verify the import
```powershell
terraform show
```

### Step 7: Plan changes
```powershell
terraform plan
```

### Step 8: Apply changes (if needed)
```powershell
terraform apply
```

## 📝 Import Process Explained

### Before Import
- S3 bucket exists in AWS but is not managed by Terraform
- No Terraform state file exists for this resource

### During Import
1. Terraform connects to AWS using the specified profile
2. Retrieves the current state of the bucket
3. Adds the bucket to the Terraform state file
4. Maps the AWS resource to the Terraform resource definition

### After Import
- Bucket is now managed by Terraform
- Any differences between actual state and configuration will be shown in `terraform plan`
- You can modify the bucket through Terraform configuration

## 🔍 Troubleshooting

### Common Issues

#### "Cannot import non-existent remote object"
**Cause**: Bucket doesn't exist or wrong AWS profile/region
```powershell
# Solutions:
# 1. Verify bucket exists
aws --profile awscc s3 ls | findstr your-bucket-name

# 2. Check you're using correct profile
$env:AWS_PROFILE="awscc"

# 3. Verify region in provider matches bucket region
aws --profile awscc s3api get-bucket-location --bucket your-bucket-name
```

#### "Resource already exists in state"
**Cause**: Resource already imported
```powershell
# Check current state
terraform state list

# Remove if needed
terraform state rm aws_s3_bucket.terraform_import
```

#### Tags being removed unexpectedly
**Cause**: Existing tags not included in configuration
**Solution**: Add existing tags to your Terraform configuration to preserve them

## 📊 State Management

### View current state
```powershell
terraform show
```

### List resources in state
```powershell
terraform state list
```

### Remove resource from state (without destroying)
```powershell
terraform state rm aws_s3_bucket.terraform_import
```

## 🧹 Cleanup

To destroy the imported resources:
```powershell
$env:AWS_PROFILE="awscc"
terraform destroy
```

**Note**: The `force_destroy = true` setting allows Terraform to delete the bucket even if it contains objects.

## 📚 Learning Outcomes

After completing this example, you will understand:

1. **How to import existing AWS resources into Terraform**
2. **The importance of matching configuration to actual state**
3. **How to handle resource tags during import**
4. **Best practices for state management**
5. **Troubleshooting common import issues**

## 🔗 Additional Resources

- [Terraform Import Documentation](https://www.terraform.io/docs/import/index.html)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [S3 Bucket Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)

## 📜 Best Practices

1. **Always backup state files** before importing
2. **Use version control** for your Terraform configurations
3. **Run `terraform plan`** before applying changes
4. **Document your import process** for team members
5. **Test imports in development** before production
6. **Use consistent naming conventions** for resources

---

**Author**: Maxwell Adomako  
**Date**: October 2025  
**Purpose**: Learning Terraform Import Functionality
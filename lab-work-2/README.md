# Terraform S3 Website Hosting Project

This project demonstrates how to use Terraform to provision an AWS S3 bucket configured for static website hosting. It creates an S3 bucket, applies the necessary bucket policies to allow public access, uploads website files, and outputs the website endpoint for easy access via a browser.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
- [How It Works](#how-it-works)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Contributing](#contributing)
- [License](#license)

## Overview

This Terraform project accomplishes the following:
- **Creates an S3 Bucket:** Provisions an S3 bucket (with a unique name) in AWS.
- **Configures Website Hosting:** Sets up the bucket for static website hosting by specifying an index and error document.
- **Applies Bucket Policies:** Applies a policy to allow public read access (and optionally, write access) to the bucket’s objects.
- **Uploads Website Files:** Uses Terraform resources to upload `index.html` and `error.html` to the bucket.
- **Outputs the Website Endpoint:** Provides the URL for accessing the hosted website.

## Prerequisites

- **Terraform:** Version 0.12 or later.
- **AWS CLI and Credentials:** Ensure you have valid AWS credentials configured. This can be done through environment variables, the AWS credentials file, or an IAM role.
- **AWS Account:** Permissions to create and manage S3 resources.
- **Web Browser:** To access and test the S3-hosted website.

## Project Structure

```
├── main.tf          # Main Terraform configuration (S3 bucket, bucket policy, S3 objects)
├── outputs.tf       # Outputs the website endpoint URL
├── variables.tf     # Variable definitions (e.g., AWS region)
├── index.html       # Static website index page
├── error.html       # Static website error page
└── README.md        # This file
```

## Setup Instructions

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/MaxiFine/terraform_repo.git
   cd lab-work-2
   ```

2. **Configure AWS Credentials:**

   Make sure your AWS credentials are set. For example, set them as environment variables:

   ```
   export AWS_ACCESS_KEY_ID=your_access_key_id
   export AWS_SECRET_ACCESS_KEY=your_secret_access_key
   export AWS_DEFAULT_REGION=your_default_region
   ```

3. **Review and Update Variables:**

   Open `variables.tf` and update any variable values if needed (for example, the AWS region).

4. **Initialize Terraform:**

   ```
   terraform init
   ```

5. **Review the Execution Plan:**

   ```
   terraform plan
   ```

6. **Apply the Terraform Configuration:**

   ```
   terraform apply
   ```
   Type `yes` when prompted to confirm.

## How It Works

- **S3 Bucket Creation:**  
  The `aws_s3_bucket` resource creates the S3 bucket.  
  Example:
  ```
  resource "aws_s3_bucket" "mx-bucket" {
    bucket = "mx-lab-work"

    website {
      index_document = "index.html"
      error_document = "error.html"
    }
  }
  ```

- **Bucket Policy:**  
  The `aws_s3_bucket_policy` resource applies a policy to allow public access to the objects.  
  *Note:* Ensure your bucket's public access settings are configured appropriately if you need public read or write access.

- **Uploading Website Files:**  
  The `aws_s3_bucket_object` resources are used to upload `index.html` and `error.html` to the bucket.

- **Output:**  
  The output value uses the (non-deprecated) `website_domain` attribute to provide the website endpoint:
  ```
  output "website_endpoint" {
    value = aws_s3_bucket.mx-bucket.website_domain
  }
  ```
  Once applied, this endpoint URL can be opened in a browser to view your static website.

## Troubleshooting

- **Deprecated Attributes:**  
  If you encounter warnings regarding deprecated attributes (e.g., `website_endpoint`), update your configuration to use the latest recommended attribute (e.g., `website_domain`).

- **File Path Issues on Windows:**  
  When specifying file paths (e.g., for the `source` argument in `aws_s3_bucket_object`), use Windows-style absolute paths or use Terraform’s built-in `path.module` variable:
  ```
  source = "${path.module}/index.html"
  ```

- **Permissions and Access Denied:**  
  Ensure your AWS IAM user/role has the necessary permissions to create and manage S3 resources and apply bucket policies.

- **HOW TO ACCESS THE INDEX AND ERROR PAGE**
    in my case::
    ```https://mx-lab-bucket.s3.eu-west-1.amazonaws.com/index.html```
    ```https://mx-lab-bucket.s3.eu-west-1.amazonaws.com/error.html```


## Cleanup

To remove all resources created by Terraform, run:

```
terraform destroy
```

Confirm by typing `yes` when prompted.

## Contributing

Contributions are welcome! If you find bugs or want to enhance the project, please feel free to fork the repository and submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

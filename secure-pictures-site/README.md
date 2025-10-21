# 🔐 Secure Pictures Website - Lambda@Edge Authentication Demo

This project demonstrates **real-world Lambda@Edge authentication** concepts for a pictures website using **Python** functions. Perfect for understanding serverless authentication, S3 static hosting, and preparing for Lambda@Edge integration!
This project demonstrates **real-world Lambda@Edge authentication** concepts for a pictures website using **Python** functions. Perfect for understanding serverless authentication, S3 static hosting, and preparing for Lambda@Edge integration!

## 🎯 Business Scenario

**The Challenge**: Your manager wants a pictures website where:
- ✅ **Homepage is public** - anyone can visit
- 🔒 **Gallery requires authentication** - must login to view pictures
- 🚫 **Direct image access blocked** - users can't access images via direct URLs
- 🛡️ **Enhanced security** - proper security headers on all responses

**The Solution**: Python Lambda functions ready for Lambda@Edge integration, currently demonstrating the authentication logic with S3 static hosting!
**The Solution**: Python Lambda functions ready for Lambda@Edge integration, currently demonstrating the authentication logic with S3 static hosting!

## 🏗️ Current Architecture
## 🏗️ Current Architecture

```
User Request → S3 Static Website → Content (with client-side auth)
     ↑                              ↓
   Response ← Authentication Check ← HTML/CSS/JS
```

**🚧 CloudFront + Lambda@Edge**: Ready to deploy when you have CloudFront permissions!

### What's Currently Working:
- 🖼️ **S3 Static Website**: Fully functional with authentication demo
- 🐍 **Lambda Functions**: Created and ready in us-east-1
- 🎨 **Beautiful UI**: Responsive design with Unsplash images
- � **Auth Logic**: Working cookie-based authentication (client-side demo)
- 📊 **Gallery**: Protected content with beautiful Unsplash images

### Current Demo Features:
- 🏠 **Public Homepage** - Explains the Lambda@Edge concept
- 🔐 **Login System** - Working demo with test credentials
- 🖼️ **Protected Gallery** - Shows authentication in action
- 🛡️ **Security Concepts** - Demonstrates edge protection patterns

**Note**: The Lambda functions are created and ready for Lambda@Edge integration when CloudFront permissions are available.
User Request → S3 Static Website → Content (with client-side auth)
     ↑                              ↓
   Response ← Authentication Check ← HTML/CSS/JS
```

**🚧 CloudFront + Lambda@Edge**: Ready to deploy when you have CloudFront permissions!

### What's Currently Working:
- 🖼️ **S3 Static Website**: Fully functional with authentication demo
- 🐍 **Lambda Functions**: Created and ready in us-east-1
- 🎨 **Beautiful UI**: Responsive design with Unsplash images
- � **Auth Logic**: Working cookie-based authentication (client-side demo)
- 📊 **Gallery**: Protected content with beautiful Unsplash images

### Current Demo Features:
- 🏠 **Public Homepage** - Explains the Lambda@Edge concept
- 🔐 **Login System** - Working demo with test credentials
- 🖼️ **Protected Gallery** - Shows authentication in action
- 🛡️ **Security Concepts** - Demonstrates edge protection patterns

**Note**: The Lambda functions are created and ready for Lambda@Edge integration when CloudFront permissions are available.

## 🚀 Quick Start

### Prerequisites
- ✅ AWS CLI configured with a profile
- ✅ Terraform installed
- ✅ Python knowledge (Lambda functions are in Python!)
- ✅ AWS CLI configured with a profile
- ✅ Terraform installed
- ✅ Python knowledge (Lambda functions are in Python!)

### Deploy in 3 Steps

1. **Navigate to Project**
1. **Navigate to Project**
   ```bash
   cd secure-pictures-site
   ```

2. **Set AWS Profile and Deploy**
2. **Set AWS Profile and Deploy**
   ```bash
   # Set your AWS profile
   export AWS_PROFILE=your-aws-profile  # Linux/Mac
   $env:AWS_PROFILE="your-aws-profile"  # Windows PowerShell
   
   # Initialize and deploy
   # Set your AWS profile
   export AWS_PROFILE=your-aws-profile  # Linux/Mac
   $env:AWS_PROFILE="your-aws-profile"  # Windows PowerShell
   
   # Initialize and deploy
   terraform init
   terraform plan
   terraform apply
   ```

3. **Access Your Live Website**
3. **Access Your Live Website**
   ```bash
   # Your S3 website is immediately available at:
   # http://secure-pictures-site-[random].s3-website-us-east-1.amazonaws.com
   
   # Check terraform output for exact URL
   terraform output s3_bucket_name
   ```

**⏰ Deployment Time**: S3 website is live immediately! Lambda functions ready for future CloudFront integration.

## 🌐 Your Live Demo

After deployment, you'll get a working website at:
```
http://secure-pictures-site-bq5ny1z4.s3-website-us-east-1.amazonaws.com
```
   # Your S3 website is immediately available at:
   # http://secure-pictures-site-[random].s3-website-us-east-1.amazonaws.com
   
   # Check terraform output for exact URL
   terraform output s3_bucket_name
   ```

**⏰ Deployment Time**: S3 website is live immediately! Lambda functions ready for future CloudFront integration.

## 🌐 Your Live Demo

After deployment, you'll get a working website at:
```
http://secure-pictures-site-bq5ny1z4.s3-website-us-east-1.amazonaws.com
```

**Demo Credentials:**
- Username: `demo` / Password: `password123`
- Username: `admin` / Password: `admin123`
**Demo Credentials:**
- Username: `demo` / Password: `password123`
- Username: `admin` / Password: `admin123`

## 🔐 How Authentication Works

### 1. **Current Demo Flow (Client-Side)**
### 1. **Current Demo Flow (Client-Side)**
```
1. User visits /gallery.html
2. JavaScript checks for auth token in cookies
3. If valid → Show gallery content
4. If invalid → Redirect to /login.html
2. JavaScript checks for auth token in cookies
3. If valid → Show gallery content
4. If invalid → Redirect to /login.html
```

### 2. **Ready Lambda Functions (Server-Side)**
### 2. **Ready Lambda Functions (Server-Side)**

#### **Authentication Function** (`auth_function.py`) - Ready for Lambda@Edge
#### **Authentication Function** (`auth_function.py`) - Ready for Lambda@Edge
```python
# Will be triggered on: Viewer Request at CloudFront edge
# Will protect: /gallery* and /data/images.json
# Will be triggered on: Viewer Request at CloudFront edge
# Will protect: /gallery* and /data/images.json
def lambda_handler(event, context):
    request = event['Records'][0]['cf']['request']
    uri = request['uri']
    
    # Allow public paths
    if uri.startswith(('/login.html', '/assets/')):
        return request
    
    # Check authentication for protected paths
    if uri.startswith(('/gallery', '/data/')):
        auth_result = check_authentication(headers)
        if auth_result['authenticated']:
            return request  # Allow access
        else:
            return redirect_to_login()  # Block access
```

#### **Security Headers Function** (`security_headers.py`) - Ready for Lambda@Edge
#### **Security Headers Function** (`security_headers.py`) - Ready for Lambda@Edge
```python
# Will be triggered on: Origin Response at CloudFront edge
# Will add security headers to ALL responses
# Will be triggered on: Origin Response at CloudFront edge
# Will add security headers to ALL responses
def lambda_handler(event, context):
    response = event['Records'][0]['cf']['response']
    
    # Add comprehensive security headers
    security_headers = {
        'strict-transport-security': 'max-age=31536000',
        'content-security-policy': "default-src 'self' https://images.unsplash.com https://images.unsplash.com",
        'x-frame-options': 'DENY',
        'x-content-type-options': 'nosniff',
        'x-xss-protection': '1; mode=block'
    }
    
    for header, value in security_headers.items():
        response['headers'][header] = [{'key': header, 'value': value}]
    
    return response
```

### 3. **Smart Architecture Design**
Instead of hosting and protecting individual images, we:
- 🌐 **Use beautiful free images from Unsplash** (better performance)
- 🔒 **Protect the gallery page and metadata file** (authentication concept)
- ⚡ **Get better performance** (images served from Unsplash's global CDN)
- 💰 **Save on storage and bandwidth costs**
- 📚 **Learn Lambda@Edge concepts** without complex image management

### 3. **Smart Architecture Design**
Instead of hosting and protecting individual images, we:
- 🌐 **Use beautiful free images from Unsplash** (better performance)
- 🔒 **Protect the gallery page and metadata file** (authentication concept)
- ⚡ **Get better performance** (images served from Unsplash's global CDN)
- 💰 **Save on storage and bandwidth costs**
- 📚 **Learn Lambda@Edge concepts** without complex image management

## 🧪 Testing Your Setup

### Demo Credentials
```
Username: demo
Password: password123

Username: admin  
Password: admin123
```

### Current Current Test Scenarios

1. **Visit Homepage**
   ```
   http://your-s3-website-url/
   # Shows Lambda@Edge concept explanation
1. **Visit Homepage**
   ```
   http://your-s3-website-url/
   # Shows Lambda@Edge concept explanation
   ```

2. **Authentication Flow Test**
   - Visit your S3 website URL
   - Click "View Gallery (Protected)"
   - Login with demo credentials
   - Access gallery with beautiful Unsplash images!

3. **Login System Test**
   - Try invalid credentials (should show error)
   - Try valid credentials (should redirect to gallery)
   - Logout and verify you're logged out

4. **Gallery Features**
   - View 6 beautiful Unsplash images
   - Responsive design works on mobile
   - Image metadata displays correctly

5. **Lambda Functions Ready**
2. **Authentication Flow Test**
   - Visit your S3 website URL
   - Click "View Gallery (Protected)"
   - Login with demo credentials
   - Access gallery with beautiful Unsplash images!

3. **Login System Test**
   - Try invalid credentials (should show error)
   - Try valid credentials (should redirect to gallery)
   - Logout and verify you're logged out

4. **Gallery Features**
   - View 6 beautiful Unsplash images
   - Responsive design works on mobile
   - Image metadata displays correctly

5. **Lambda Functions Ready**
   ```bash
   # Check your deployed Lambda functions
   aws lambda list-functions --region us-east-1 | grep pictures-site
   # Should show: pictures-site-auth and pictures-site-security-headers
   # Check your deployed Lambda functions
   aws lambda list-functions --region us-east-1 | grep pictures-site
   # Should show: pictures-site-auth and pictures-site-security-headers
   ```

### 🔮 Future CloudFront Integration
When CloudFront permissions are available, the Lambda functions will provide:
- Edge-based authentication (faster!)
- Global protection at all edge locations
- Real server-side security (not just client-side demo)
### 🔮 Future CloudFront Integration
When CloudFront permissions are available, the Lambda functions will provide:
- Edge-based authentication (faster!)
- Global protection at all edge locations
- Real server-side security (not just client-side demo)

## 🛡️ Security Features

### 🔒 **Edge Authentication**
- Authentication happens at CloudFront edge locations
- Faster than origin-based auth
- Reduces load on your backend
- Global protection

### 🎟️ **Token-Based System**
- JWT-like tokens with HMAC signatures
- 24-hour expiration
- Stored in secure cookies
- Cryptographically signed

### 🛡️ **Comprehensive Security Headers**
```
✅ Strict-Transport-Security
✅ Content-Security-Policy  
✅ X-Frame-Options
✅ X-Content-Type-Options
✅ X-XSS-Protection
✅ Referrer-Policy
✅ Permissions-Policy
```

### �️ **Access Controls**
- Path-based protection (`/gallery*`, `/images/metadata.json`)
- Cookie-based session management
- Automatic redirect for unauthorized users
- Smart design: Gallery metadata protected, images served from public CDN

## 📁 Project Structure

```
secure-pictures-site/
├── main.tf                    # Complete infrastructure (S3 + Lambda functions) (S3 + Lambda functions)
├── variables.tf               # Configuration options
├── outputs.tf                 # URLs and deployment info  
├── outputs.tf                 # URLs and deployment info  
├── lambda/
│   ├── auth_function.py       # Python authentication logic (Lambda@Edge ready)
│   ├── security_headers.py    # Python security headers (Lambda@Edge ready)
│   ├── auth_function.zip      # Generated deployment package
│   └── security_headers.zip   # Generated deployment package
├── README.md                 # This comprehensive guide
└── Deployed S3 Objects:
    ├── index.html            # Public homepage (embedded in main.tf)
    ├── login.html            # Authentication page (embedded in main.tf)  
    ├── gallery.html          # Protected gallery (embedded in main.tf)
    ├── assets/styles.css     # Responsive styling (embedded in main.tf)
    └── data/images.json      # Gallery metadata with Unsplash URLs
```

**Note**: The website files are embedded directly in the Terraform configuration for simplicity. The Lambda functions are in separate Python files ready for Lambda@Edge integration.
│   ├── auth_function.py       # Python authentication logic (Lambda@Edge ready)
│   ├── security_headers.py    # Python security headers (Lambda@Edge ready)
│   ├── auth_function.zip      # Generated deployment package
│   └── security_headers.zip   # Generated deployment package
├── README.md                 # This comprehensive guide
└── Deployed S3 Objects:
    ├── index.html            # Public homepage (embedded in main.tf)
    ├── login.html            # Authentication page (embedded in main.tf)  
    ├── gallery.html          # Protected gallery (embedded in main.tf)
    ├── assets/styles.css     # Responsive styling (embedded in main.tf)
    └── data/images.json      # Gallery metadata with Unsplash URLs
```

**Note**: The website files are embedded directly in the Terraform configuration for simplicity. The Lambda functions are in separate Python files ready for Lambda@Edge integration.

## 🔧 Configuration Options

### Variables You Can Customize

```terraform
# Session duration
variable "session_duration_hours" {
  default = 24  # Change to your preference
}

# User management
variable "allowed_users" {
  default = {
    "demo"  = "password123"
    "admin" = "admin123"
  }
}

# CloudFront settings
variable "cloudfront_price_class" {
  default = "PriceClass_100"  # Global: PriceClass_All
}
```

### Environment Customization

```bash
# Custom values
terraform apply -var="session_duration_hours=8" \
                -var="cloudfront_price_class=PriceClass_All"
```

## 🌍 Real-World Applications

### **E-commerce Platforms**
- Protect premium product images
- Member-only content areas
- Exclusive product galleries

### **Media & Entertainment**
- Subscriber-only content
- Premium video thumbnails
- VIP member galleries

### **Corporate Websites**
- Employee-only resources
- Client-specific content
- Internal documentation

### **Educational Platforms**
- Course materials protection
- Student resource areas
- Premium content access

## 📊 Monitoring & Debugging

### CloudWatch Logs
Lambda@Edge logs are distributed globally:
```bash
# Check logs in multiple regions
aws logs describe-log-groups --region us-east-1 | grep lambda-edge
aws logs describe-log-groups --region eu-west-1 | grep lambda-edge
```

### Debug Headers
The functions add helpful debug headers:
```
X-Authenticated-User: demo
X-Security-Processed: true
X-Processed-At: 1640995200
```

### Performance Monitoring
```sql
-- CloudWatch Insights query
fields @timestamp, @message
| filter @message like /Authentication/
| stats count() by bin(5m)
```

## 🔄 Advanced Customizations

### Add More Security
```python
# In security_headers.py, add:
headers['content-security-policy'] = [{
    'key': 'Content-Security-Policy',
    'value': "default-src 'self'; img-src 'self' https://trusted-cdn.com"
}]
```

### Custom Authentication
```python
# In auth_function.py, integrate with:
# - AWS Cognito
# - External OAuth providers
# - Database-backed user management
# - Multi-factor authentication
```

### Geo-based Rules
```python
# Add location-based access controls
country = headers.get('cloudfront-viewer-country', [{}])[0].get('value')
if country in ['US', 'CA', 'GB']:
    # Allow access
    return request
else:
    # Redirect or block
    return create_error_response(403)
```

## ⚠️ Important Notes

### Current Status
- ✅ **S3 Static Website**: Fully deployed and working
- ✅ **Lambda Functions**: Created in us-east-1 (ready for Lambda@Edge)
- ✅ **CloudFront**: Ready to deploy (requires correct AWS profile)
- 🎯 **Demo Purpose**: Perfect for learning Lambda@Edge concepts

### 🔧 Troubleshooting Common Issues

#### AWS Profile/Account Issues
If you get permission errors like `AccessDenied`, check your AWS profile:

```bash
# Check current identity
aws sts get-caller-identity

# List available profiles
aws configure list-profiles

# Set correct profile (the one used during initial deployment)
export AWS_PROFILE=awscc          # Linux/Mac
$env:AWS_PROFILE="awscc"          # Windows PowerShell

# Verify correct account
aws sts get-caller-identity
# Should show Account: 382828593864 (or your deployment account)
```

#### S3 Versioning Errors
```
Error: operation error S3: GetBucketVersioning... AccessDenied
```
**Root Cause**: Wrong AWS profile - resources were created in different account  
**Solution**: Set correct AWS profile (see AWS Profile section above)

#### CloudFront Permission Errors
```
Error: User is not authorized to perform: cloudfront:CreateDistribution
```
**Solutions**:
1. Use an AWS profile with CloudFront permissions (like `awscc`)
2. Or continue with S3-only demo (still valuable for learning!)

#### Terraform State Issues
```bash
# If terraform seems confused about state:
terraform refresh

# If resources exist but terraform doesn't know about them:
terraform import aws_s3_bucket.pictures_website secure-pictures-site-bq5ny1z4
```

#### Region Issues
- ✅ Lambda functions must be in `us-east-1` for Lambda@Edge
- ✅ S3 bucket can be in any region  
- ✅ Current setup: All resources in `us-east-1`

#### Quick Fix Commands
```bash
# Reset to working state
cd secure-pictures-site
$env:AWS_PROFILE="awscc"
terraform refresh
terraform plan
```

### Lambda@Edge Requirements (When Adding CloudFront)
- **Region**: Functions must be created in `us-east-1` ✅ (Already done!)
- **Memory**: 128MB (viewer events), 1GB (origin events)  
- **Timeout**: 5s (viewer events), 30s (origin events)
- **No VPC**: Cannot access VPC resources
- **No Environment Variables**: Not supported

### Current Demo vs Production
| Feature | Current Demo | Production Ready |
|---------|-------------|------------------|
| Authentication | Client-side demo | Server-side Lambda@Edge |
| User Storage | Hardcoded | AWS Cognito/Database |
| Secrets | Hardcoded | AWS Secrets Manager |
| Security | Basic | Comprehensive headers |
| Scalability | S3 limits | Global CloudFront |

### Current Demo vs Production
| Feature | Current Demo | Production Ready |
|---------|-------------|------------------|
| Authentication | Client-side demo | Server-side Lambda@Edge |
| User Storage | Hardcoded | AWS Cognito/Database |
| Secrets | Hardcoded | AWS Secrets Manager |
| Security | Basic | Comprehensive headers |
| Scalability | S3 limits | Global CloudFront |

### Production Considerations
- Use AWS Secrets Manager for secrets
- Implement proper user management (AWS Cognito)
- Add rate limiting
- Use real JWT libraries
- Implement proper logging
- Add monitoring and alerting

## 🧹 Cleanup

```bash
terraform destroy
```

**Note**: Lambda@Edge cleanup takes time as functions are removed from all edge locations.

## 🤝 Next Steps

### Enhance This Demo
1. **Add AWS Cognito integration**
2. **Implement proper JWT handling**
3. **Add rate limiting**
4. **Create admin dashboard**
5. **Add image upload functionality**

### Production Deployment
1. **Use proper secrets management**
2. **Implement proper user database**
3. **Add monitoring and alerting**
4. **Set up CI/CD pipeline**
5. **Add automated testing**

## 📚 Learning Resources

- [AWS Lambda@Edge Documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-at-the-edge.html)
- [Python Lambda Functions](https://docs.aws.amazon.com/lambda/latest/dg/python-programming-model.html)
- [CloudFront Security Best Practices](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/SecurityBestPractices.html)

---

## 🎉 Success!

You now have a working demo and Lambda@Edge foundation:
- ✅ **Live S3 Website**: Working authentication demo
- ✅ **Lambda Functions**: Ready for Lambda@Edge integration (Python)
- ✅ **Authentication Concepts**: Working login/logout system  
- ✅ **Beautiful UI**: Responsive design with Unsplash images
- ✅ **Infrastructure as Code**: Complete Terraform setup
- ✅ **Learning Platform**: Perfect for understanding serverless auth

## 🔮 Next Steps

### Immediate (Working Now)
1. ✅ Visit your live S3 website: `http://secure-pictures-site-bq5ny1z4.s3-website-us-east-1.amazonaws.com`
2. ✅ Test the authentication flow with demo credentials
3. ✅ Explore the Lambda functions code
4. ✅ Understand the serverless architecture

### Deploy Full Lambda@Edge (Optional)
If you have CloudFront permissions and want the full Lambda@Edge experience:

```bash
# Ensure correct AWS profile
$env:AWS_PROFILE="awscc"

# Deploy CloudFront + Lambda@Edge
terraform apply

# Wait 15-30 minutes for global propagation
# Then test your CloudFront URL with real edge authentication!
```

### Future Enhancements
1. 🔐 **Add CloudFront**: Real Lambda@Edge integration (available now!)
2. 👥 **Add Cognito**: Proper user management
3. 🔒 **Add Secrets Manager**: Secure credential storage
4. 📊 **Add Monitoring**: CloudWatch insights and alarms
5. 🌍 **Multi-region**: Expand beyond us-east-1

Perfect for demonstrating serverless authentication concepts and Lambda@Edge readiness to your manager! 🚀
Perfect for demonstrating serverless authentication concepts and Lambda@Edge readiness to your manager! 🚀

---

**Built with** ❤️ **using AWS Lambda, S3 Static Hosting, and Terraform**  
**Ready for** 🚀 **AWS Lambda@Edge and CloudFront integration**
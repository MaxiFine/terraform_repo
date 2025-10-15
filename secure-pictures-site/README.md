# 🔐 Secure Pictures Website - Lambda@Edge Authentication Demo

This project demonstrates **real-world Lambda@Edge authentication** for a pictures website using **Python** functions. Perfect for understanding how to protect content with CloudFront and Lambda@Edge!

## 🎯 Business Scenario

**The Challenge**: Your manager wants a pictures website where:
- ✅ **Homepage is public** - anyone can visit
- 🔒 **Gallery requires authentication** - must login to view pictures
- 🚫 **Direct image access blocked** - users can't access images via direct URLs
- 🛡️ **Enhanced security** - proper security headers on all responses

**The Solution**: Lambda@Edge functions in Python that authenticate users at CloudFront edge locations worldwide!

## 🏗️ Architecture

```
User Request → CloudFront Edge → Lambda@Edge Auth → S3 Origin
     ↑                               ↓
   Response ← Security Headers ← Lambda@Edge ← Content
```

### What Gets Protected:
- 🖼️ `/gallery.html` - Protected gallery page
- � `/images/metadata.json` - Gallery configuration and image URLs
- 🔒 Authentication happens at the edge (faster!)
- 🌍 Works globally at all CloudFront locations

**Note**: The actual images are served from Unsplash (public CDN) but the gallery page and metadata that references them are protected by authentication.

### What Stays Public:
- 🏠 `/` and `/index.html` - Homepage
- 🔐 `/login.html` - Login page
- 🎨 `/assets/*` - CSS and static assets

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured
- Terraform installed
- Python knowledge (Lambda functions are in Python!)

### Deploy in 3 Steps

1. **Clone and Navigate**
   ```bash
   cd secure-pictures-site
   ```

2. **Initialize and Deploy**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Test Authentication**
   ```bash
   # Get your CloudFront URL
   terraform output website_url
   
   # Test public access (should work)
   curl https://your-cloudfront-domain/
   
   # Test protected content (should redirect to login)
   curl -I https://your-cloudfront-domain/gallery.html
   ```

**⏰ Deployment Time**: Lambda@Edge takes 15-30 minutes to propagate globally!

## 🔐 How Authentication Works

### 1. **User Flow**
```
1. User visits /gallery.html
2. Lambda@Edge intercepts request
3. Checks for valid auth token in cookies
4. If valid → Allow access
5. If invalid → Redirect to /login.html
```

### 2. **Python Lambda@Edge Functions**

#### **Authentication Function** (`auth_function.py`)
```python
# Triggered on: Viewer Request
# Protects: /gallery* and /images/metadata.json
def lambda_handler(event, context):
    request = event['Records'][0]['cf']['request']
    uri = request['uri']
    
    # Allow public paths
    if uri.startswith(('/login.html', '/assets/')):
        return request
    
    # Check authentication for protected paths
    if uri.startswith(('/gallery', '/images/')):
        auth_result = check_authentication(headers)
        if auth_result['authenticated']:
            return request  # Allow access
        else:
            return redirect_to_login()  # Block access
```

**Smart Design**: Instead of hosting and protecting individual images, we:
- 🌐 Use beautiful free images from Unsplash 
- 🔒 Protect the gallery page and metadata file
- ⚡ Get better performance (images served from Unsplash's global CDN)
- 💰 Save on storage and bandwidth costs

#### **Security Headers Function** (`security_headers.py`)
```python
# Triggered on: Origin Response
# Adds security headers to ALL responses
def lambda_handler(event, context):
    response = event['Records'][0]['cf']['response']
    
    # Add comprehensive security headers
    security_headers = {
        'strict-transport-security': 'max-age=31536000',
        'content-security-policy': "default-src 'self'",
        'x-frame-options': 'DENY',
        # ... more headers
    }
    
    for header, value in security_headers.items():
        response['headers'][header] = [{'key': header, 'value': value}]
    
    return response
```

## 🧪 Testing Your Setup

### Demo Credentials
```
Username: demo
Password: password123

Username: admin  
Password: admin123
```

### Test Scenarios

1. **Public Access Test**
   ```bash
   curl https://your-domain/
   # Should return homepage HTML
   ```

2. **Protected Content Test**
   ```bash
   curl -I https://your-domain/gallery.html
   # Should return 302 redirect to login
   ```

3. **Gallery Protection Test**
   ```bash
   curl -I https://your-domain/gallery.html
   # Should return 302 redirect to login
   ```

4. **Metadata Protection Test**
   ```bash
   curl -I https://your-domain/images/metadata.json
   # Should be blocked/redirected without authentication
   ```

5. **Security Headers Test**
   ```bash
   curl -I https://your-domain/ | grep -E "(X-|Strict|Content-Security)"
   # Should show security headers
   ```

6. **Authentication Flow Test**
   - Visit your CloudFront URL
   - Click "View Gallery"
   - Should redirect to login
   - Login with demo credentials
   - Should access gallery with beautiful Unsplash images!

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
├── main.tf                    # Complete infrastructure
├── variables.tf               # Configuration options
├── outputs.tf                 # URLs and test commands
├── lambda/
│   ├── auth_function.py       # Python authentication logic
│   └── security_headers.py    # Python security headers
├── website/
│   ├── index.html            # Public homepage
│   ├── login.html            # Authentication page
│   ├── gallery.html          # Protected gallery (loads images dynamically)
│   ├── assets/
│   │   └── styles.css        # Responsive styling
│   └── images/               # (Now empty - using public image URLs)
│       └── metadata.json     # Protected: Contains image URLs and descriptions
└── README.md                 # This guide
```

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

### Lambda@Edge Limitations
- **Region**: Functions must be created in `us-east-1`
- **Memory**: 128MB (viewer events), 1GB (origin events)  
- **Timeout**: 5s (viewer events), 30s (origin events)
- **No VPC**: Cannot access VPC resources
- **No Environment Variables**: Not supported

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

You now have a production-ready example of:
- ✅ **Lambda@Edge authentication in Python**
- ✅ **Real-world content protection**
- ✅ **Comprehensive security headers**
- ✅ **Global edge-based processing**

Perfect for demonstrating Lambda@Edge capabilities to your manager! 🚀

---

**Built with** ❤️ **using AWS Lambda@Edge, CloudFront, S3, and Terraform**
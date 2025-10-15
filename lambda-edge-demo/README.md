# 🚀 Lambda@Edge Demo - Edge Computing with AWS

This project demonstrates **AWS Lambda@Edge** capabilities through a practical, hands-on example. You'll learn how to process HTTP requests and responses at CloudFront edge locations worldwide for improved performance and functionality.

## 🎯 What You'll Learn

- **Lambda@Edge fundamentals** and architecture
- **Request/Response processing** at edge locations
- **Security header injection** for improved website security
- **A/B testing implementation** using edge computing
- **Geo-location based processing** and content customization
- **CloudFront integration** with Lambda@Edge
- **Terraform Infrastructure as Code** for Lambda@Edge

## 🏗️ Architecture Overview

```
    User Request
         ↓
   CloudFront Edge Location
         ↓
   Lambda@Edge Functions
    ↙            ↘
Viewer Request   Origin Response
Processing       Processing
    ↓               ↑
   S3 Origin ──────┘
```

### Components

- **S3 Bucket**: Static website hosting
- **CloudFront Distribution**: Global CDN with edge processing
- **Lambda@Edge Functions**: 
  - Security Headers (Origin Response)
  - A/B Testing (Viewer Request)
- **IAM Roles**: Proper permissions for edge execution

## 🔧 Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Node.js knowledge (for understanding Lambda functions)
- Basic understanding of CloudFront and S3

## 📁 Project Structure

```
lambda-edge-demo/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── lambda/
│   ├── security-headers.js    # Security headers Lambda@Edge function
│   └── ab-testing.js          # A/B testing Lambda@Edge function
├── website/
│   ├── index.html       # Main demo page (Version A)
│   └── about.html       # Information about the demo
└── README.md           # This file
```

## 🚀 Quick Start

### 1. Clone and Navigate
```bash
cd lambda-edge-demo
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review the Plan
```bash
terraform plan
```

### 4. Deploy the Infrastructure
```bash
terraform apply
```

**⚠️ Note**: Lambda@Edge deployment can take 15-30 minutes to propagate globally.

### 5. Test Your Setup
After deployment, Terraform will output the CloudFront domain. Test it:

```bash
# Get the domain from output
terraform output cloudfront_url

# Test the website
curl -I https://your-cloudfront-domain.cloudfront.net

# Check security headers
curl -I https://your-domain/ | grep -E "(X-|Strict|Content-Security)"
```

## 🧪 Lambda@Edge Functions Explained

### 1. Security Headers Function

**Trigger**: Origin Response  
**Purpose**: Automatically add security headers to all responses

```javascript
// Headers added:
- Strict-Transport-Security
- Content-Security-Policy
- X-Content-Type-Options
- X-Frame-Options
- X-XSS-Protection
- Referrer-Policy
- Permissions-Policy
```

**Benefits**:
- Improved security posture
- Automated header management
- Consistent security across all pages
- No need to modify origin servers

### 2. A/B Testing Function

**Trigger**: Viewer Request  
**Purpose**: Route users to different page versions based on consistent hashing

```javascript
// Logic:
1. Generate or retrieve user ID from cookies
2. Create consistent hash from user ID
3. Assign variant (A or B) based on hash
4. Modify request URI for variant B
5. Add tracking headers
```

**Benefits**:
- Consistent user experience (same user always sees same variant)
- No backend changes required
- Real-time traffic splitting
- Minimal latency impact

## 🌍 Testing Different Scenarios

### A/B Testing
```bash
# Clear cookies and test multiple times
curl -c cookies.txt -b cookies.txt https://your-domain/
curl -c cookies.txt -b cookies.txt https://your-domain/
```

### Security Headers
```bash
# Check all security headers
curl -I https://your-domain/ | grep -E "(X-|Strict|Content-Security|Referrer)"
```

### Geo-location Simulation
```bash
# Simulate requests from different countries
curl -H "CloudFront-Viewer-Country: US" https://your-domain/
curl -H "CloudFront-Viewer-Country: GB" https://your-domain/
curl -H "CloudFront-Viewer-Country: DE" https://your-domain/
```

### Performance Testing
```bash
# Test response times from different locations
time curl -o /dev/null -s https://your-domain/
```

## 📊 Monitoring and Debugging

### CloudWatch Logs
Lambda@Edge logs are distributed across regions. Check logs in:
- The region closest to where requests originated
- Use CloudWatch Insights for aggregated analysis

### Useful CloudWatch Queries
```sql
-- Find A/B test distributions
fields @timestamp, @message
| filter @message like /A\/B Test/
| stats count() by bin(5m)

-- Monitor security header function
fields @timestamp, @message  
| filter @message like /Security headers/
| stats count() by bin(5m)
```

### Debug Headers
The functions add debug headers you can inspect:
- `X-Processed-By`: Identifies which Lambda@Edge function processed the request
- `X-AB-Variant`: Shows A/B test variant assignment
- `X-Edge-Processing-Time`: Timestamp of edge processing

## 🔧 Customization Options

### Modify A/B Test Split
Edit `lambda/ab-testing.js`:
```javascript
// Change the percentage split
const variant = (hash % 100) < 30 ? 'A' : 'B'; // 30/70 split
```

### Add More Security Headers
Edit `lambda/security-headers.js`:
```javascript
headers['x-custom-header'] = [{
    key: 'X-Custom-Header',
    value: 'Your custom value'
}];
```

### Geo-location Rules
Add geo-specific logic in `ab-testing.js`:
```javascript
// Example: Redirect users from specific countries
if (country === 'DE') {
    request.uri = '/de/index.html';
}
```

## 💡 Real-World Use Cases

### 1. E-commerce
- **Product Recommendations**: Personalize based on location/device
- **Pricing**: Show region-specific pricing
- **Inventory**: Display availability based on geographic location

### 2. Content Platforms
- **Content Localization**: Serve region-appropriate content
- **A/B Testing**: Test different layouts, CTAs, or features
- **Performance**: Optimize images/content based on connection speed

### 3. Security Applications
- **Bot Detection**: Implement sophisticated bot detection at edge
- **Rate Limiting**: Apply rate limits before reaching origin
- **Authentication**: Validate JWTs or API keys at edge

### 4. SEO Optimization
- **Dynamic Meta Tags**: Modify SEO tags based on user agent
- **Canonical URLs**: Implement proper URL canonicalization
- **Redirects**: Handle complex redirect logic

## ⚠️ Important Limitations

### Lambda@Edge Constraints
- **Region**: Functions must be created in `us-east-1`
- **Memory**: 128MB (viewer events), 1GB (origin events)
- **Timeout**: 5s (viewer events), 30s (origin events)
- **No VPC Access**: Cannot access VPC resources
- **No Environment Variables**: Not supported
- **Limited Libraries**: Some Node.js libraries may not work

### Best Practices
- **Keep functions lightweight**: Minimize execution time
- **Error handling**: Always include proper error handling
- **Logging**: Use console.log for debugging (logs go to CloudWatch)
- **Testing**: Test thoroughly before production deployment

## 🧹 Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Note**: Lambda@Edge function deletion can take additional time as replicas need to be removed from all edge locations.

## 📚 Additional Resources

- [AWS Lambda@Edge Documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-at-the-edge.html)
- [Lambda@Edge Use Cases](https://aws.amazon.com/lambda/edge/)
- [CloudFront Events That Trigger Lambda@Edge](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-cloudfront-trigger-events.html)
- [Lambda@Edge Function Examples](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-examples.html)

## 🤝 Contributing

Feel free to extend this demo with additional Lambda@Edge use cases:
- Image optimization
- JWT validation
- Advanced bot detection
- Content compression
- Cache optimization

---

**Happy Learning!** 🎉

This demo provides a solid foundation for understanding Lambda@Edge. Experiment with the functions, modify the logic, and explore the possibilities of edge computing with AWS!
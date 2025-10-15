import json

def lambda_handler(event, context):
    """
    Lambda@Edge function to add security headers
    Triggered on Origin Response
    """
    response = event['Records'][0]['cf']['response']
    headers = response['headers']
    
    print("Adding security headers to response")
    
    # Security headers for picture website
    security_headers = {
        'strict-transport-security': {
            'key': 'Strict-Transport-Security',
            'value': 'max-age=31536000; includeSubDomains; preload'
        },
        'content-security-policy': {
            'key': 'Content-Security-Policy',
            'value': "default-src 'self'; img-src 'self' data: https:; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; font-src 'self' https:; connect-src 'self';"
        },
        'x-content-type-options': {
            'key': 'X-Content-Type-Options',
            'value': 'nosniff'
        },
        'x-frame-options': {
            'key': 'X-Frame-Options',
            'value': 'DENY'
        },
        'x-xss-protection': {
            'key': 'X-XSS-Protection',
            'value': '1; mode=block'
        },
        'referrer-policy': {
            'key': 'Referrer-Policy',
            'value': 'strict-origin-when-cross-origin'
        },
        'permissions-policy': {
            'key': 'Permissions-Policy',
            'value': 'geolocation=(), microphone=(), camera=(), payment=(), usb=()'
        },
        'cross-origin-embedder-policy': {
            'key': 'Cross-Origin-Embedder-Policy',
            'value': 'require-corp'
        },
        'cross-origin-opener-policy': {
            'key': 'Cross-Origin-Opener-Policy',
            'value': 'same-origin'
        },
        'cross-origin-resource-policy': {
            'key': 'Cross-Origin-Resource-Policy',
            'value': 'same-origin'
        }
    }
    
    # Add security headers to response
    for header_name, header_config in security_headers.items():
        headers[header_name] = [header_config]
    
    # Add custom headers for identification and debugging
    headers['x-powered-by'] = [{
        'key': 'X-Powered-By',
        'value': 'AWS Lambda@Edge'
    }]
    
    headers['x-security-processed'] = [{
        'key': 'X-Security-Processed',
        'value': 'true'
    }]
    
    # Add cache control for different content types
    content_type = headers.get('content-type', [{}])[0].get('value', '')
    
    if 'text/html' in content_type:
        # HTML pages - no cache for dynamic content
        headers['cache-control'] = [{
            'key': 'Cache-Control',
            'value': 'public, max-age=0, must-revalidate'
        }]
    elif any(img_type in content_type for img_type in ['image/jpeg', 'image/png', 'image/gif', 'image/webp']):
        # Images - cache for longer with auth consideration
        headers['cache-control'] = [{
            'key': 'Cache-Control',
            'value': 'private, max-age=3600'  # Cache for 1 hour for authenticated users
        }]
    elif 'text/css' in content_type or 'application/javascript' in content_type:
        # CSS and JS - cache for longer
        headers['cache-control'] = [{
            'key': 'Cache-Control',
            'value': 'public, max-age=86400'  # Cache for 1 day
        }]
    
    # Add header to indicate processing timestamp
    import time
    headers['x-processed-at'] = [{
        'key': 'X-Processed-At',
        'value': str(int(time.time()))
    }]
    
    print(f"Security headers added successfully. Content-Type: {content_type}")
    
    return response
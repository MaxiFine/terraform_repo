import json
import base64
import hmac
import hashlib
import time
from urllib.parse import parse_qs, urlparse, urlencode
import re

# Configuration - In production, these should come from AWS Systems Manager Parameter Store
SECRET_KEY = "demo-secret-key-change-in-production"
SESSION_DURATION = 24 * 3600  # 24 hours in seconds
ALLOWED_USERS = {
    "demo": "password123",
    "admin": "admin123", 
    "user1": "mypassword"
}

def lambda_handler(event, context):
    """
    Lambda@Edge function for authentication
    Protects /gallery* and /images/* paths
    """
    request = event['Records'][0]['cf']['request']
    headers = request['headers']
    uri = request['uri']
    
    print(f"Processing request for URI: {uri}")
    
    # Allow access to public pages
    public_paths = ['/', '/index.html', '/login.html', '/assets/']
    
    if any(uri.startswith(path) for path in public_paths):
        print(f"Allowing access to public path: {uri}")
        return request
    
    # Check if accessing protected content
    if uri.startswith('/gallery') or uri.startswith('/images/'):
        print(f"Checking authentication for protected path: {uri}")
        
        # Check for valid authentication
        auth_result = check_authentication(headers)
        
        if auth_result['authenticated']:
            print(f"User {auth_result['username']} authenticated successfully")
            # Add user info to headers for downstream processing
            request['headers']['x-authenticated-user'] = [{'key': 'X-Authenticated-User', 'value': auth_result['username']}]
            return request
        else:
            print(f"Authentication failed: {auth_result['reason']}")
            # Redirect to login page
            return create_redirect_response('/login.html?redirect=' + uri)
    
    # Default: allow request
    return request

def check_authentication(headers):
    """
    Check if the request contains valid authentication
    """
    # Look for authentication token in cookies
    cookie_header = headers.get('cookie')
    if not cookie_header:
        return {'authenticated': False, 'reason': 'No cookies found'}
    
    cookies = {}
    for cookie in cookie_header:
        cookie_pairs = cookie['value'].split(';')
        for pair in cookie_pairs:
            if '=' in pair:
                key, value = pair.split('=', 1)
                cookies[key.strip()] = value.strip()
    
    auth_token = cookies.get('auth_token')
    if not auth_token:
        return {'authenticated': False, 'reason': 'No auth token found'}
    
    # Validate the token
    try:
        payload = validate_token(auth_token)
        if payload:
            username = payload.get('username')
            exp = payload.get('exp', 0)
            
            # Check if token is expired
            if time.time() > exp:
                return {'authenticated': False, 'reason': 'Token expired'}
            
            return {'authenticated': True, 'username': username}
        else:
            return {'authenticated': False, 'reason': 'Invalid token'}
            
    except Exception as e:
        print(f"Token validation error: {str(e)}")
        return {'authenticated': False, 'reason': f'Token validation error: {str(e)}'}

def validate_token(token):
    """
    Validate JWT-like token (simplified implementation for demo)
    In production, use proper JWT library
    """
    try:
        # Simple token format: base64(header).base64(payload).signature
        parts = token.split('.')
        if len(parts) != 3:
            return None
        
        header_encoded, payload_encoded, signature = parts
        
        # Decode payload
        payload_json = base64.b64decode(payload_encoded + '==').decode('utf-8')
        payload = json.loads(payload_json)
        
        # Verify signature
        expected_signature = create_signature(header_encoded + '.' + payload_encoded)
        if not hmac.compare_digest(signature, expected_signature):
            return None
        
        return payload
        
    except Exception as e:
        print(f"Token validation error: {str(e)}")
        return None

def create_signature(data):
    """
    Create HMAC signature for token
    """
    return base64.b64encode(
        hmac.new(
            SECRET_KEY.encode('utf-8'),
            data.encode('utf-8'),
            hashlib.sha256
        ).digest()
    ).decode('utf-8').rstrip('=')

def create_redirect_response(location):
    """
    Create a redirect response to login page
    """
    return {
        'status': '302',
        'statusDescription': 'Found',
        'headers': {
            'location': [{'key': 'Location', 'value': location}],
            'cache-control': [{'key': 'Cache-Control', 'value': 'no-cache, no-store, must-revalidate'}],
            'pragma': [{'key': 'Pragma', 'value': 'no-cache'}],
            'expires': [{'key': 'Expires', 'value': '0'}]
        }
    }
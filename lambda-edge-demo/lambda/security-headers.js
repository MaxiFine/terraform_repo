/**
 * Lambda@Edge function to add security headers
 * Triggered on Origin Response
 */
exports.handler = async (event) => {
    const response = event.Records[0].cf.response;
    const headers = response.headers;

    // Add security headers
    headers['strict-transport-security'] = [{
        key: 'Strict-Transport-Security',
        value: 'max-age=31536000; includeSubDomains; preload'
    }];

    headers['content-security-policy'] = [{
        key: 'Content-Security-Policy',
        value: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' https:;"
    }];

    headers['x-content-type-options'] = [{
        key: 'X-Content-Type-Options',
        value: 'nosniff'
    }];

    headers['x-frame-options'] = [{
        key: 'X-Frame-Options',
        value: 'DENY'
    }];

    headers['x-xss-protection'] = [{
        key: 'X-XSS-Protection',
        value: '1; mode=block'
    }];

    headers['referrer-policy'] = [{
        key: 'Referrer-Policy',
        value: 'strict-origin-when-cross-origin'
    }];

    headers['permissions-policy'] = [{
        key: 'Permissions-Policy',
        value: 'geolocation=(), microphone=(), camera=()'
    }];

    // Add custom header to identify Lambda@Edge processing
    headers['x-processed-by'] = [{
        key: 'X-Processed-By',
        value: 'Lambda@Edge-Security-Headers'
    }];

    // Add timestamp
    headers['x-edge-processing-time'] = [{
        key: 'X-Edge-Processing-Time',
        value: new Date().toISOString()
    }];

    console.log('Security headers added successfully');
    return response;
};
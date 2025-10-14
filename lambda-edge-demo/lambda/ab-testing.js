/**
 * Lambda@Edge function for A/B Testing
 * Triggered on Viewer Request
 */
exports.handler = async (event) => {
    const request = event.Records[0].cf.request;
    const headers = request.headers;
    
    // Get or create user identifier
    let userId = null;
    if (headers.cookie) {
        const cookies = headers.cookie[0].value;
        const userIdMatch = cookies.match(/userId=([^;]+)/);
        if (userIdMatch) {
            userId = userIdMatch[1];
        }
    }
    
    // Generate userId if not exists
    if (!userId) {
        userId = Math.random().toString(36).substring(2, 15);
    }
    
    // Determine A/B test variant based on userId hash
    const hash = simpleHash(userId);
    const variant = (hash % 100) < 50 ? 'A' : 'B'; // 50/50 split
    
    // Modify request based on variant
    if (variant === 'B' && request.uri === '/') {
        request.uri = '/index-b.html';
    } else if (variant === 'B' && request.uri === '/index.html') {
        request.uri = '/index-b.html';
    }
    
    // Add custom headers for tracking
    request.headers['x-ab-variant'] = [{
        key: 'X-AB-Variant',
        value: variant
    }];
    
    request.headers['x-user-id'] = [{
        key: 'X-User-ID',
        value: userId
    }];
    
    // Add geolocation-based logic
    const country = headers['cloudfront-viewer-country'] 
        ? headers['cloudfront-viewer-country'][0].value 
        : 'US';
    
    // Redirect UK users to a specific page
    if (country === 'GB' && request.uri === '/') {
        request.uri = '/uk-landing.html';
    }
    
    // Log for debugging
    console.log(`A/B Test - User: ${userId}, Variant: ${variant}, Country: ${country}, URI: ${request.uri}`);
    
    return request;
};

// Simple hash function for consistent A/B testing
function simpleHash(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        const char = str.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash; // Convert to 32-bit integer
    }
    return Math.abs(hash);
}
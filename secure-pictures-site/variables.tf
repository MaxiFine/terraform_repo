variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
  
  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.cloudfront_price_class)
    error_message = "Price class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "sample_images" {
  description = "List of public image URLs to use in the gallery"
  type = list(object({
    url         = string
    filename    = string
    title       = string
    description = string
  }))
  default = [
    {
      url         = "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop"
      filename    = "mountain-landscape.jpg"
      title       = "Mountain Landscape"
      description = "Breathtaking mountain vista with snow-capped peaks"
    },
    {
      url         = "https://images.unsplash.com/photo-1439066615861-d1af74d74000?w=800&h=600&fit=crop"
      filename    = "lake-sunset.jpg"
      title       = "Lake Sunset"
      description = "Serene lake reflecting the golden sunset"
    },
    {
      url         = "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800&h=600&fit=crop"
      filename    = "city-skyline.jpg"
      title       = "City Skyline"
      description = "Modern urban skyline at dusk"
    },
    {
      url         = "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&h=600&fit=crop"
      filename    = "forest-path.jpg"
      title       = "Forest Path"
      description = "Peaceful woodland trail surrounded by tall trees"
    },
    {
      url         = "https://images.unsplash.com/photo-1506197603052-3cc9c3a201bd?w=800&h=600&fit=crop"
      filename    = "ocean-waves.jpg"
      title       = "Ocean Waves"
      description = "Powerful ocean waves crashing on rocky shore"
    },
    {
      url         = "https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=800&h=600&fit=crop"
      filename    = "desert-dunes.jpg"
      title       = "Desert Dunes"
      description = "Golden sand dunes stretching to the horizon"
    }
  ]
}

variable "auth_secret_key" {
  description = "Secret key for JWT token generation (in production, use AWS Secrets Manager)"
  type        = string
  default     = "demo-secret-key-change-in-production"
  sensitive   = true
}

variable "session_duration_hours" {
  description = "How long authentication sessions last (in hours)"
  type        = number
  default     = 24
}

variable "allowed_users" {
  description = "Map of allowed users and their passwords (in production, use proper authentication service)"
  type        = map(string)
  default = {
    "demo"    = "password123"
    "admin"   = "admin123"
    "user1"   = "mypassword"
  }
  sensitive = true
}
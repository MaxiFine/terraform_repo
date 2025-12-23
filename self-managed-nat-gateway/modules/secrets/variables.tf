variable "name" {
    description             = "Name for the secrets."
    type                    = string
}

variable "description" {
    description             = "Description for the secrets."
    type                    = string
}

variable "secret_string" {
    description             = "Secret String passed as raw json"
    type                    = any
    sensitive               = true
}

variable "environment" {
    description             = "Secret String passed as raw json"
    type                    = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

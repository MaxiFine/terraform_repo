variable "key_name" {
    description                 = "Name provided to the aws_key_pair module."
    type                        = string
}

variable "rsa_algorithm" {
    description                 = "Algorithm used to key generation."
    type                        = string
    default                     = "RSA"
}

variable "rsa_bits" {
    description                 = "Level of encryption."
    type                        = number
    default                     = 4096
}

variable "tags" {
    description                 = "Tags to be passed to the aws_key_pair module."
    type                        = map(string)
    default                     = {}
}

output "output" {
    description             = "Public output for tls key"
    value                   = { "key_name": aws_key_pair.main.key_name, 
                                "public_key": tls_private_key.primary_key.public_key_pem
                              }
}

output "sensitive_output" {
    description             = "Private output for tls key"
    value                   = { "pem" : tls_private_key.primary_key.private_key_pem }
    sensitive               = true
}


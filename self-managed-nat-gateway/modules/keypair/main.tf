resource "tls_private_key" "primary_key" {
    algorithm                       = var.rsa_algorithm
    rsa_bits                        = var.rsa_bits
}


resource "aws_key_pair" "main" {
    key_name                        = "${var.key_name}"
    public_key                      = tls_private_key.primary_key.public_key_openssh
    tags                            = "${merge(var.tags,
                                                tomap({"Name" = "${var.key_name} AWS Key Pair"}))}"
}


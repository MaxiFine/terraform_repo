# data "aws_ssm_parameter" "amazon_linux_ami" {
#   name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
# }


# data "aws_ssm_parameter" "ubuntu_22_04" {
#   name = "/aws/service/canonical/ubuntu/server-jammy/stable/current/amd64/hvm/ebs-gp2/ami-id"
# }

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical’s AWS account
  
}

resource "aws_instance" "public_instance" {
  # ami           = data.aws_ssm_parameter.amazon_linux_ami.value
  # ami           = data.aws_ssm_parameter.ubuntu_22_04.value
  ami                    = data.aws_ami.ubuntu.id
  instance_type = var.public_instance_type
  subnet_id = var.public_subnet_id
  security_groups        = [var.public_security_group_id]
  key_name               = var.key_name
  vpc_security_group_ids = [var.public_security_group_id]
  user_data              = file("${path.root}/user_data.sh")
  associate_public_ip_address = true  # Ensures the instance gets a public routing IP address

  tags = {
    Name = "Public|Instance"
    Environment = "Development"
  }

}


resource "aws_instance" "private_instance" {
  # ami                    = data.aws_ssm_parameter.amazon_linux_ami.value
  # ami                    = data.aws_ssm_parameter.ubuntu_22_04.value
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.public_instance_type
  subnet_id              = var.private_subnet_id
  security_groups        = [var.private_security_group_id]
  key_name               = var.key_name
  vpc_security_group_ids = [var.private_security_group_id]
  user_data              = file("${path.module}/user_data.sh")


  tags = {
    Name        = "Private|Instance"
  }

}

# #################
# ## Key Pair not used in this version

# #################
# ## Key Pair
# resource "tls_private_key" "rsa" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
#   #   region    = var.aws_region
# }


# resource "aws_key_pair" "mx_key_pair" {
#   key_name = var.key_name
#   #   public_key = file("${path.module}/keys/${var.key_name}.pub")
#   public_key = tls_private_key.rsa.public_key_openssh
#   # provider = var.aws_region == "eu-north-1" ? aws.eu_north_1 : aws.default
#   # provider = var.aws_region


#   tags = {
#     Name        = "MxProject-KeyPair"
#     Environment = "Development"
#   }
# }


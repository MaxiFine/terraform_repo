data "aws_ssm_parameter" "amazon_linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}


resource "aws_instance" "public_instance" {
  ami                    = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type          = var.public_instance_type
  subnet_id              = module.networking.public_subnet_id
  security_groups        = [module.security_groups.public_security_group_id]
  key_name               = var.key_name
  vpc_security_group_ids = [var.public_security_group_id]
  user_data              = file("${path.module}/user_data.sh")


  tags = {
    Name        = "Public Instance"
    Environment = "Development"
  }

}


resource "aws_instance" "private_instance" {
  ami                    = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type          = var.public_instance_type
  subnet_id              = module.networking.private_subnet_id
  security_groups        = [module.security_groups.private_security_group_id]
  key_name               = var.key_name
  vpc_security_group_ids = [var.public_security_group_id]
  user_data              = file("${path.module}/user_data.sh")


  tags = {
    Name        = "Public Instance"
    Environment = "Development"
  }

}
# ec2 compute module
resource "aws_instance" "app_server" {
    ami           = var.ami
    instance_type = var.instance_type
    subnet_id    = aws_subnet.subnet.id
    tags = {
        Name = var.instance_name
    }
  
}
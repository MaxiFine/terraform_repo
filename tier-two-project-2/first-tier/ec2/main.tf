#Create the EC2 Instances
resource "aws_instance" "web1" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  key_name                    = "tier-2-key"
  availability_zone           = "us-east-1a"
  vpc_security_group_ids      = var.security_group_id
  subnet_id                   = module.vpc.privatesub_1
  associate_public_ip_address = true
  user_data                   = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>Hey there! Go refill your coffee. We have more to do!</h1></body></html>" > /var/www/html/index.html
        EOF

  tags = {
    Name = "web1_instance"
  }
}
resource "aws_instance" "web2" {
  ami                         = var.ami
  instance_type               = var.instance_type
key_name                    = "tier-2-key"
  availability_zone           = "us-east-1b"
  
#   vpc_security_group_ids      = [aws_security_group.public_sg.id]
  vpc_security_group_ids      = var.security_group_id
  security_groups = module.security_group.security_group_id
  subnet_id                   = module.vpc.publicsub_2
  associate_public_ip_address = true
  user_data                   = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>Hey fellow Terraform learners!</h1></body></html>" > /var/www/html/index.html
        EOF
        

  tags = {
    Name = "web2_instance"
  }
}
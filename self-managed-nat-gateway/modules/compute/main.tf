data "aws_ami" "validate" {
  count  = var.ami_id != null ? 1 : 0
  owners = ["self", "amazon", "099720109477"]

  filter {
    name   = "image-id"
    values = [var.ami_id]
  }
}

# Default to latest Ubuntu
data "aws_ami" "ubuntu_latest" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  selected_ami = var.ami_id != null ? data.aws_ami.validate[0].id : data.aws_ami.ubuntu_latest[0].id
}


#################################
## USING Page configurations
data "aws_ami" "amzn_linux_2023_ami" {
  most_recent                       = true
  owners                            = ["amazon"]
  filter {
    name                            = "name"
    values                          = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "aws_nat_gateway_instance" {
    count                           = length(var.public_subnet_ids)
    ami                             = var.nat_instance_ami_id
    instance_type                   = "t3.small"
    subnet_id                       = element(var.public_subnet_ids[*], count.index)
    vpc_security_group_ids          = [aws_security_group.nat_instance_sg.id]
    associate_public_ip_address     = true
    source_dest_check               = false
    user_data                       = <<-EOL
                                        #! /bin/bash
                                        sudo yum install iptables-services -y
                                        sudo systemctl enable iptables
                                        sudo systemctl start iptables
                                        sudo sysctl -w net.ipv4.ip_forward=1
                                        sudo /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
                                        sudo /sbin/iptables -F FORWARD
    EOL
    user_data_replace_on_change     = true
    key_name                        = var.ec2_key_name

    root_block_device {
        volume_size                 = "8"
        volume_type                 = "gp2"
        encrypted                   = true
    }
    tags                            = "${merge(var.tags,
                                                tomap({"Name" = "NAT EC2 Instance ${count.index + 1}"}))}"
}

resource "aws_instance" "nat_testing_aws_instances" {
    count                           = var.create_nat_testing_instances ? length(var.private_subnet_ids) : 0
    ami                             = data.aws_ami.amzn_linux_2023_ami.id
    instance_type                   = "t2.micro"
    subnet_id                       = element(var.private_subnet_ids[*], count.index)
    vpc_security_group_ids          = [aws_security_group.nat_testing_instance_sg.id]
    key_name                        = var.ec2_key_name

    root_block_device {
        volume_size                 = "8"
        volume_type                 = "gp2"
        encrypted                   = true
    }

    tags                            = "${merge(var.tags,
                                                tomap({"Name" = "NAT Testing EC2 Instance ${count.index + 1}"}))}"            
}
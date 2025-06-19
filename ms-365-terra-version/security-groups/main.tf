resource "aws_security_group" "public_sg" {
    name = "public_security_group"
    description = "Security group for public resources"
    vpc_id = var.vpc_id
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port   = 22
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name        = "Public Security Group"
        Environment = "Development"
    }
}     

#######################
## Private Security Group
resource "aws_security_group" "private_sg" {
    name = "private_security_group"
    description = "Security group for private resources"
    vpc_id = var.vpc_id

    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        security_groups = [aws_security_group.public_sg.id]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        # cidr_blocks = ["0.0.0.0/0"]
        security_groups = [aws_security_group.public_sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name        = "Private Security Group"
        Environment = "Development"
    }
}

resource "aws_security_group" "nat_instance_sg" {
    name                = "nat_instance_sg"
    description         = "Security Group for NAT Instance."
    vpc_id              = var.main_vpc_id

    tags                = {
        Name            = "NAT Instance security group"
        terraform       = true
        environment     = "test"
    }
}

resource "aws_security_group" "nat_testing_instance_sg" {
    name                = "nat_testing_instance_sg"
    description         = "Security Group for NAT Testing Instance."
    vpc_id              = var.main_vpc_id

    tags                = {
        Name            = "NAT Testing Instance security group"
        terraform       = true
        environment     = "test"
    }
}
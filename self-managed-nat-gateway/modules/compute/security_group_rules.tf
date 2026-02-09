resource "aws_security_group_rule" "nat_instance_inbound_sg_rule" {
    type                = "ingress"
    from_port           = 0
    to_port             = 0
    protocol            = "-1"
    cidr_blocks         = [var.main_cidr_block]
    security_group_id   = aws_security_group.nat_instance_sg.id
}

resource "aws_security_group_rule" "ssh_ingress_from_public_ip" {
    count               = length(var.private_ips_for_ssh) > 0 ? 1 : 0
    type                = "ingress"
    from_port           = 22
    to_port             = 22
    protocol            = "tcp"
    #this allows private ingress from whatever ip you specify as a variable
    # cidr_blocks         = var.private_ips_for_ssh
    # cidr_blocks         = list(aws_instance.aws_nat_gateway_instance[*].private_ip, "/32")
    cidr_blocks = [for ip in aws_instance.aws_nat_gateway_instance[*].private_ip : "${ip}/32"]
    security_group_id   = aws_security_group.nat_instance_sg.id
}

resource "aws_security_group_rule" "ipv4_egress_from_private_subnets" {
    type                = "egress"
    from_port           = 0
    to_port             = 0
    protocol            = "-1"
    cidr_blocks         = var.private_cidr_blocks
    security_group_id   = aws_security_group.nat_instance_sg.id
}

resource "aws_security_group_rule" "ssh_egress_to_private_subnets" {
    type                = "egress"
    from_port           = 22
    to_port             = 22
    protocol            = "tcp"
    cidr_blocks         = var.private_cidr_blocks
    security_group_id   = aws_security_group.nat_instance_sg.id
}

resource "aws_security_group_rule" "nat_instance_output_sg_rule" {
    type                = "egress"
    from_port           = 0
    to_port             = 0
    protocol            = "-1"
    cidr_blocks         = ["0.0.0.0/0"]
    security_group_id   = aws_security_group.nat_instance_sg.id
}

resource "aws_security_group_rule" "nat_testing_instance_ingress" {
    type                = "ingress"
    from_port           = 0
    to_port             = 0
    protocol            = "-1"
    cidr_blocks         = var.public_cidr_blocks
    security_group_id   = aws_security_group.nat_testing_instance_sg.id
}

resource "aws_security_group_rule" "nat_testing_instance_egress" {
    type                = "egress"
    from_port           = 0
    to_port             = 0
    protocol            = "-1"
    cidr_blocks         = ["0.0.0.0/0"]
    security_group_id   = aws_security_group.nat_testing_instance_sg.id
}


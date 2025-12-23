
# Locals like tfvars for staging environment

locals {
    vpc_name                            = "NAT Instance VPC"
    key_pair_name                      = "example_ssh_key_pem"
    key_pair_description               = "pem used for NAT Instance connection"
    nat_instance_key_name               = "nat_instance_key"
    main_cidr_block                     = "10.0.0.0/16"
    public_cidr_blocks                  = ["10.0.1.0/24", "10.0.2.0/24"]
    private_cidr_blocks                 = ["10.0.5.0/24", "10.0.6.0/24"]
    region                              = "eu-west-1"
    availability_zones                  = ["eu-west-1a", "eu-west-1b"]
    private_ips_for_ssh                 = [aws_instance.test_instance.private_ip] #replace with your ips
    nat_instance_ami_id                 = "ami-09abb6457c770f890"
    tags                                = {
        Environment                         = "staging"
        Terraform                           = true
    }
}


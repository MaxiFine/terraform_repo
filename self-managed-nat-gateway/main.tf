module "vpc" {
    source                              = "terraform-aws-modules/vpc/aws"
    name                                = var.vpc_name
    cidr                                = var.main_cidr_block
    public_subnets                      = var.public_cidr_blocks
    private_subnets                     = var.private_cidr_blocks
    azs                                 = var.availability_zones
    tags                                = var.tags
}

module "nat_instance_key_pair" {
    source                              = "./module/key_pair"
    key_name                            = var.nat_instance_key_name
    tags                                = var.tags
}

module "ssh_key_secret" {
    source                              = "./module/secrets"
    name                                = var.ssh_key_secret_name
    description                         = var.ssh_key_secret_description
    secret_string                       = module.nat_instance_key_pair.sensitive_output.pem
    tags                                = var.tags
}

module "nat_instances" {
    source                              = "./module/nat_instance"
    nat_instance_ami_id                 = var.nat_instance_ami_id
    main_vpc_id                         = module.vpc.vpc_id
    main_cidr_block                     = var.main_cidr_block
    public_cidr_blocks                  = var.public_cidr_blocks
    create_nat_testing_instances        = true
    private_cidr_blocks                 = var.private_cidr_blocks
    public_subnet_ids                   = module.vpc.public_subnets
    private_subnet_ids                  = module.vpc.private_subnets
    private_subnet_route_table_ids      = module.vpc.private_route_table_ids
    private_ips_for_ssh                 = var.private_ips_for_ssh
    ec2_key_name                        = module.example_nat_instance_key_pair.output.key_name
    region                              = var.region
    tags                                = var.tags
}


module "vpc" {
    source                              = "terraform-aws-modules/vpc/aws"
    name                                = local.vpc_name
    cidr                                = local.main_cidr_block
    public_subnets                      = local.public_cidr_blocks
    private_subnets                     = local.private_cidr_blocks
    azs                                 = local.availability_zones
    tags                                = local.tags
}

module "nat_instance_key_pair" {
    source                              = "../module/key_pair"
    key_name                            = local.nat_instance_key_name
    tags                                = local.tags
}

module "ssh_key_secret" {
    source                              = "../module/secrets"
    name                                = local.ssh_key_secret_name
    description                         = local.ssh_key_secret_description
    secret_string                       = module.nat_instance_key_pair.sensitive_output.pem
    tags                                = local.tags
}

module "nat_instances" {
    source                              = "../module/nat_instance"
    nat_instance_ami_id                 = local.nat_instance_ami_id
    main_vpc_id                         = module.vpc.vpc_id
    main_cidr_block                     = local.main_cidr_block
    public_cidr_blocks                  = local.public_cidr_blocks
    create_nat_testing_instances        = true
    private_cidr_blocks                 = local.private_cidr_blocks
    public_subnet_ids                   = module.vpc.public_subnets
    private_subnet_ids                  = module.vpc.private_subnets
    private_subnet_route_table_ids      = module.vpc.private_route_table_ids
    private_ips_for_ssh                 = local.private_ips_for_ssh
    ec2_key_name                        = module.nat_instance_key_pair.output.key_name
    region                              = local.region
    tags                                = local.tags
}


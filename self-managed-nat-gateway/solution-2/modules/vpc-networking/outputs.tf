output "vpc_id" {
    description = "The ID of the VPC"
    value       = module.vpc.vpc_id
}

output "public_subnet_cird" {
    description = "Public Subnet Cird"
    value = module.vpc.public_subnets
}


output "private_subnet_cird" {
    description = "Private Subnet Cird"
    value = module.vpc.private_subnets
}

output "public_subnets_id" {
  description = "Public Subnets ID's"
  value = module.vpc.public_subnet_arns
}


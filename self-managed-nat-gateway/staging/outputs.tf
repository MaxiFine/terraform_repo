output "nat_instances_output" {
    description             = "NAT Instances Output"
    value                   = module.compute.private_instance_ip_1
}

output "nat_testing_instances_output" {
    description             = "NAT Testing Instances Output"
    value                   = module.compute.private_instance_ip_2
}


resource "aws_route" "outbound_nat_route" {
    count                       = length(var.private_subnet_ids)
    route_table_id              = element(var.private_subnet_route_table_ids[*], count.index)
    destination_cidr_block      = "0.0.0.0/0"
    network_interface_id        = element(aws_instance.nat_aws_instances[*].primary_network_interface_id, count.index)
}


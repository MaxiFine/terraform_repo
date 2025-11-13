 
variable default_region {
    type = string
    description = "the region this infrastructure is in"
    # default = "ap-southeast-1"
    default = "eu-west-1"
}
 
variable instance_size {
    type = string
    description = "ec2 web server size"
    default = "t2.micro"
}

variable infra_env {
    type = map(string)
    default =  {
        staging = "infra-staging"
        production   = "infra-production"
        Purpose = "Define environment names for infrastructure"
        Task = "Manage multiple environments using workspaces"
    }
}
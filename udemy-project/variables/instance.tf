resource "aws_key_pair" "levelup_key" {
    key_name   = "levelup_key"

    public_key = file(var.PATH_TO_PRIVATE_KEY)
  
}

resource "aws_instance" "web_server" {
    # ami           = var.amis[var.aws_region]
    ami           = lookup(var.amis, var.aws_region)
    instance_type = "t2.micro"
    key_name      = aws_key_pair.levelup_key.key_name
    tags = {
      Name = "terraInstance"
    }

    provisioner "file" {
    source      = "install_nginx.sh"
    destination = "/tmp/install_nginx.sh"
    }


    provisioner "remote-exec" {
    inline = [

        "chmod +x /tmp/install_nginx.sh",
        "sudo sed -i -e 's/\r$//'  /tmp/install_nginx.sh",
        "sudo /tmp/install_nginx.sh",
      "sudo apt-get update",
      "sudo apt-get install -y nginx"
    ]
    }
    # connection {
    #     host        = coalesce(self.public_ip, self.private_ip)
    #   type        = "ssh"
    #   user        = var.INSTANCE_USERNAME
    #   private_key = file(var.PATH_TO_PRIVATE_KEY)
    # }
  


    
    connection {
        host        = coalesce(self.public_ip, self.private_ip)
      type        = "ssh"
      user        = var.INSTANCE_USERNAME
      private_key = file(var.PATH_TO_PRIVATE_KEY)
    }
  
    # when = "create"
  
}
  





    # when = "create"
  

# resource "aws_db_instance" "db" {
#   allocated_storage    = 20
#   storage_type         = "gp2"
#   engine               = "mysql"
#   engine_version       = "5.7"
#   instance_class       = "db.t2.micro"
#   name                 = "mydb"
#   username             = "foo"
#   password             = "bar"
#   parameter_group_name = "default.mysql5.7"
#   publicly_accessible  = true
#   skip_final_snapshot  = true
#   vpc_security_group_ids = [aws_security_group.rds_sg.id]
#   tags = {
#     Name = "mydb"
#   }
  
# }

resource "aws_db_instance" "db" {
  engine         = "mysql"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  db_subnet_group_name = aws_db_subnet_group.db_subnets.name
}

resource "aws_db_subnet_group" "db_subnets" {
  name       = "db-subnet-group"
  subnet_ids = var.private_subnets
}

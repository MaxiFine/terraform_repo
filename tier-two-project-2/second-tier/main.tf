#Configure the Data Base Private Subnet Group
resource "aws_db_subnet_group" "db_subnet" {
  name       = "db-subnet"
  subnet_ids = [aws_subnet.privatesub_1.id, aws_subnet.privatesub_2.id]
}

#Create the Data Base Instance
resource "aws_db_instance" "project_db" {
  allocated_storage      = 5
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  identifier             = "db-instance"
  db_name                = "project_db"
  username               = "admin"
  password               = "password"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}


# Create a security group for the RDS instance
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16"]  # Allow traffic within the VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# Create a MariaDB RDS instance
resource "aws_db_instance" "mariadb" {
  allocated_storage    = 20
  engine               = "mariadb"
  instance_class       = "db.t3.micro"
  db_name              = "mydb"
  username             = "admin"
  password             = "password"  # Replace with a secure password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot = true
  tags = {
    Name = "mariadb-instance"
  }
}

# Create a subnet group for the RDS instance
resource "aws_db_subnet_group" "main" {
  name       = "main-subnet-group"
  subnet_ids = [aws_subnet.private.id,aws_subnet.private_b.id]

  tags = {
    Name = "main-subnet-group"
  }
}

resource "aws_db_instance" "mariadb_replica" {
  identifier              = "mariadb-replica"
  engine                  = aws_db_instance.mariadb.engine
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  username                = "admin"
  password                = "password123"
  skip_final_snapshot     = true
  replicate_source_db     = aws_db_instance.mariadb.id

  tags = {
    Name = "mariadb-replica"
  }
}
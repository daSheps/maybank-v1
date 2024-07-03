output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "ec2_instance_id" {
  value = aws_instance.ssm-host.id
}

output "rds_instance_endpoint" {
  value = aws_db_instance.mariadb.endpoint
}

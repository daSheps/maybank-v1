# Create a security group for the EC2 instance
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

# # Create an server EC2 instance
# resource "aws_instance" "web" {
#   ami           = "ami-0c55b159cbfafe1f0"  # Replace with a suitable AMI
#   instance_type = "t2.micro"
#   subnet_id     = aws_subnet.private.id
#   security_groups = [aws_security_group.ec2_sg.name]
#   iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
#   user_data = <<-EOF
#                 #!/bin/bash
#                 yum install -y amazon-ssm-agent
#                 systemctl enable amazon-ssm-agent
#                 systemctl start amazon-ssm-agent
#               EOF

#   tags = {
#     Name = "web-instance"
#   }
# }

# Create an EC2 instance
resource "aws_instance" "ssm-host" {
  ami           = "ami-008c09a18ce321b3c"  # Replace with a suitable AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  associate_public_ip_address = true

  user_data = <<-EOF
                #!/bin/bash
                yum install -y amazon-ssm-agent
                systemctl enable amazon-ssm-agent
                systemctl start amazon-ssm-agent
              EOF

  tags = {
    Name = "ssm_host-instance"
  }
}

# Create an IAM role for the EC2 instance
resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "ssm_instance_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create an instance profile for the EC2 instance
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}




// WEB SERVER 

resource "aws_launch_template" "web-app" {
  name_prefix   = "web-app"
  image_id      = "ami-0c51d572f6477d468"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Install the Amazon SSM Agent
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF
  )

  // Define other configurations as needed
}

resource "aws_autoscaling_group" "example" {
  launch_template {
    id      = aws_launch_template.web-app.id
    version = "$Latest"
  }

  desired_capacity     = 2
  min_size             = 1
  max_size             = 3
  vpc_zone_identifier  = [aws_subnet.private.id, aws_subnet.private_b.id]  // Specify your subnets

  // Define other ASG configurations as needed
}

# Define input variables
variable "security_group_name" {
  description = "Name of the security group"
  type        = string
}

variable "pem_file_name" {
  description = "Name of the PEM file to be created"
  type        = string
}

variable "existing_vpc_id" {
  description = "ID of the existing VPC to be used"
  type        = string
}

# Define AWS provider block
provider "aws" {
  # No need to specify access_key and secret_key if already configured in AWS CLI
}

# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = var.existing_vpc_id
  tags = {
    Name = "my-igw"
  }
}

# Attach Internet Gateway to VPC
resource "aws_vpc_attachment" "my_vpc_attachment" {
  vpc_id             = var.existing_vpc_id
  internet_gateway_id = aws_internet_gateway.my_igw.id
}

# Create Public Subnet 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id     = var.existing_vpc_id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Change to your preferred availability zone
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

# Create Public Subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id     = var.existing_vpc_id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b" # Change to your preferred availability zone
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}

# Create Security Group
resource "aws_security_group" "my_security_group" {
  name_prefix = var.security_group_name

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Ubuntu 22.04 instance
resource "aws_instance" "my_instance" {
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t2.large"
  subnet_id     = aws_subnet.public_subnet_1.id
  key_name      = var.pem_file_name
  security_groups = [aws_security_group.my_security_group.name]
}

# Generate the private key file
resource "null_resource" "generate_key" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "${aws_instance.my_instance.key_name}" > ${var.pem_file_name}.pem
    EOT
  }
}

# Output the public IP addresses of the instances
output "public_ip_addresses" {
  value = aws_instance.my_instance.public_ip
}

# Output the private key file location
output "private_key_path" {
  value = "${path.module}/${var.pem_file_name}.pem"
}

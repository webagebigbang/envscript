# Define input variable for security group name
variable "security_group_name" {
  description = "Name of the security group"
  type        = string
}

# Define input variable for PEM file name
variable "pem_file_name" {
  description = "Name of the PEM file to be created"
  type        = string
}

# Define the AWS provider block
provider "aws" {
  // No need to specify access_key and secret_key if already configured in AWS CLI
}

# Define a security group resource
resource "aws_security_group" "my_security_group" {
  name_prefix = var.security_group_name

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Open all ports for simplicity. In production, limit to necessary ports and sources.
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define the Ubuntu 22.04 instance
resource "aws_instance" "my_instance" {
  ami           = "ami-0c94855ba95c71c99" # Ubuntu 22.04 LTS AMI ID
  instance_type = "t2.large"

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

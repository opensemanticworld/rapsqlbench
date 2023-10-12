# Tell Terraform to use the AWS and local Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

# Configure the AWS Provider to interact with AWS services
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Create a Virtual Private Cloud (VPC) to provide a network for the resources
resource "aws_vpc" "tf-aws-vpc-1" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = var.env_tag
  }
}

# Create a subnet within the VPC for the resources
resource "aws_subnet" "tf-aws-subnet-1" {
  vpc_id     = aws_vpc.tf-aws-vpc-1.id
  availability_zone = var.aws_availability_zone
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = var.env_tag
  }
}

# Add a tag to the default route table
resource "aws_default_route_table" "tf-aws-rt-1" {
  default_route_table_id = aws_vpc.tf-aws-vpc-1.default_route_table_id
  tags = {
    Name = var.env_tag
  }
}

# Create an Internet Gateway (IGW) to allow the VPC to connect to the Internet
resource "aws_internet_gateway" "tf-aws-gw-1" {
  vpc_id = aws_vpc.tf-aws-vpc-1.id
  tags = {
    Name = var.env_tag
  }
}

# Create a route to the Internet Gateway
resource "aws_route" "tf-aws-rt-1" {
  route_table_id         = aws_default_route_table.tf-aws-rt-1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tf-aws-gw-1.id
}

# Associate the route table with the subnet
resource "aws_route_table_association" "tf-aws-rt-assoc-1" {
  subnet_id      = aws_subnet.tf-aws-subnet-1.id
  route_table_id = aws_default_route_table.tf-aws-rt-1.id
}

# Create a security group within the VPC to allow SSH access to the resources
resource "aws_security_group" "tf-aws-sg-1" {
  name        = "allow-ssh"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.tf-aws-vpc-1.id
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.env_tag
  }
}

# Add a ssh key pair to the AWS account (optional)
resource "aws_key_pair" "tf-aws-key-pair-1" {
  key_name   = "sysmon-raeder-rsa-key-1"
  public_key = file("~/.ssh/id_rsa.pub")
  tags = {
    Name = var.env_tag
  }
}

# Create an ubuntu 22.04 vm instance
resource "aws_instance" "tf-aws-ubuntu-instance-1" {
  ami                    = "ami-04e601abe3e1a910f"
  instance_type          = "t2.micro"
  availability_zone      = var.aws_availability_zone
  key_name               = aws_key_pair.tf-aws-key-pair-1.key_name # change this to var
  vpc_security_group_ids = [aws_security_group.tf-aws-sg-1.id]
  subnet_id              = aws_subnet.tf-aws-subnet-1.id
  depends_on             = [aws_internet_gateway.tf-aws-gw-1]
  tags = {
    Name = var.env_tag
  }
}

# Create a public IP address for the instance
resource "aws_eip" "tf-aws-eip-1" {
  instance   = aws_instance.tf-aws-ubuntu-instance-1.id
  domain     = "vpc"
  depends_on = [aws_internet_gateway.tf-aws-gw-1]
  tags = {
    Name = var.env_tag
  }
}

# Create a local file with the public IP address associated with the instance
resource "local_file" "tf-vm-pubip-1" {
  content  = aws_eip.tf-aws-eip-1.public_ip
  filename = "${path.module}/tf-vm-pubip-1-inventory.txt"
}

resource "aws_ebs_volume" "tf-aws-ebs-1" {
  availability_zone = var.aws_availability_zone
  size              = 1
  type              = "gp3"
  iops              = 3000
  throughput        = 125   #MiB/s
  tags = {
    Name = var.env_tag
  }
}

resource "aws_volume_attachment" "tf-aws-ebs-1" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.tf-aws-ebs-1.id
  instance_id = aws_instance.tf-aws-ubuntu-instance-1.id
}

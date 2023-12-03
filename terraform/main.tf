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
resource "aws_vpc" "tf-aws-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = var.env_tag
  }
}

# Create a subnet within the VPC for the resources
resource "aws_subnet" "tf-aws-subnet" {
  vpc_id            = aws_vpc.tf-aws-vpc.id
  availability_zone = var.aws_availability_zone
  cidr_block        = "10.0.0.0/24"
  tags = {
    Name = var.env_tag
  }
}

# Add a tag to the default route table
resource "aws_default_route_table" "tf-aws-rt" {
  default_route_table_id = aws_vpc.tf-aws-vpc.default_route_table_id
  tags = {
    Name = var.env_tag
  }
}

# Create an Internet Gateway (IGW) to allow the VPC to connect to the Internet
resource "aws_internet_gateway" "tf-aws-gw" {
  vpc_id = aws_vpc.tf-aws-vpc.id
  tags = {
    Name = var.env_tag
  }
}

# Create a route to the Internet Gateway
resource "aws_route" "tf-aws-rt" {
  route_table_id         = aws_default_route_table.tf-aws-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tf-aws-gw.id
}

# Associate the route table with the subnet
resource "aws_route_table_association" "tf-aws-rt-assoc-1" {
  subnet_id      = aws_subnet.tf-aws-subnet.id
  route_table_id = aws_default_route_table.tf-aws-rt.id
}

# Create a security group within the VPC to allow SSH access to the resources
resource "aws_security_group" "tf-aws-sg" {
  name        = "allow-ssh"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.tf-aws-vpc.id
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
resource "aws_key_pair" "tf-aws-key-pair" {
  key_name   = var.ssh_key_name
  public_key = file("~/.ssh/id_rsa.pub")
  tags = {
    Name = var.env_tag
  }
}

# Create an ubuntu 22.04 vm instance mapping
resource "aws_instance" "tf-aws-ubuntu-instance" {
  for_each = var.vm_map

  ami                    = each.value.ami
  instance_type          = each.value.instance_type
  availability_zone      = var.aws_availability_zone
  key_name               = var.ssh_key_name # check if works
  vpc_security_group_ids = [aws_security_group.tf-aws-sg.id]
  subnet_id              = aws_subnet.tf-aws-subnet.id
  depends_on             = [aws_internet_gateway.tf-aws-gw]
  root_block_device {
    volume_size = each.value.ebs_size
    volume_type = var.ebs_type
    iops        = var.ebs_iops
    throughput  = var.ebs_throughput
  }
  tags = {
    Name = var.env_tag
  }
}

# Create a public IP address for the mapped instances
resource "aws_eip" "tf-aws-eip" {
  for_each = var.vm_map

  instance   = aws_instance.tf-aws-ubuntu-instance[each.key].id
  domain     = "vpc"
  depends_on = [aws_internet_gateway.tf-aws-gw]
  tags = {
    Name = var.env_tag
  }
}

# Create a local public IP file with associated and mapped instance
resource "local_file" "tf-aws-eip-loc" {
  for_each = var.vm_map

  content  = aws_eip.tf-aws-eip[each.key].public_ip
  filename = "${path.module}/inventory/${each.key}-eip.txt"
}

# # Create an EBS volume mapping 
# resource "aws_ebs_volume" "tf-aws-ebs" {
#   for_each = var.vm_map

#   availability_zone = var.aws_availability_zone
#   size              = each.value.ebs_size
#   type              = "gp3"
#   iops              = 3000
#   throughput        = 125 #MiB/s
#   tags = {
#     Name = var.env_tag
#   }
# }

# # Attach the EBS volume to the mapped instances
# resource "aws_volume_attachment" "tf-aws-ebs" {
#   for_each = var.vm_map

#   device_name = "/dev/sdh"
#   volume_id   = aws_ebs_volume.tf-aws-ebs[each.key].id
#   instance_id = aws_instance.tf-aws-ubuntu-instance[each.key].id
# }

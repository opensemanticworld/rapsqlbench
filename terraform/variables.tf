# Provider
variable "aws_region" {
  type    = string
  default = "eu-central-1" # Change this to your region
}

# Availability Zone 
variable "aws_availability_zone" {
  type    = string
  default = "eu-central-1a" # Change this to your availability zone
}

variable "aws_profile" {
  type    = string
  default = "sysarch" # Change this to your profile name from sso session
}

# Enviorenment 
variable "env_tag" {
  type    = string
  default = "tf-aws-rapsqlbench"
}

# SSH Key 
variable "ssh_key_name" {
  type    = string
  default = "radearan-sysarch-rsa" # Change this to your ssh key name
}

# EBS Volume Type
variable "ebs_type" {
  type    = string
  default = "gp3"
}

# EBS Volume IOPS
variable "ebs_iops" {
  type    = number
  default = 3000
}

# EBS Volume Throughput
variable "ebs_throughput" {
  type    = number
  default = 125
}

# Unique VM resource mapping including public IP, local IP file, and EBS
variable "vm_map" {
  type = map(object({
    ami           = string
    instance_type = string
    ebs_size      = number
  }))
  default = {
    # "vmtest" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "t2.micro"
    #   ebs_size      = 30
    # }
    # "vm100" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "r5.8xlarge"
    #   ebs_size      = 30
    # }
    # "vm50k" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "r5.8xlarge"
    #   ebs_size      = 100
    # }
    # "vm250k22" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "r5.8xlarge"
    #   ebs_size      = 250
    # }
    # "vm1m" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "r5.8xlarge"
    #   ebs_size      = 150
    # }
    # "vm5m" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "r5.8xlarge"
    #   ebs_size      = 150
    # }
    "vm125mr2" = {
      ami           = "ami-04e601abe3e1a910f"
      instance_type = "r5.8xlarge"
      ebs_size      = 600
    }
    "vm250mr2" = {
      ami           = "ami-04e601abe3e1a910f"
      instance_type = "r5.8xlarge"
      ebs_size      = 1200
    }
    "vm500mr2" = {
      ami           = "ami-04e601abe3e1a910f"
      instance_type = "r5.8xlarge"
      ebs_size      = 2400
    }
    "vm1bnr2" = {
      ami           = "ami-04e601abe3e1a910f"
      instance_type = "r5.8xlarge"
      ebs_size      = 4800
    }
  }
}



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

# Unique VM resource mapping including public IP, local IP file, and EBS
variable "vm_map" {
  type = map(object({
    ami           = string
    instance_type = string
    ebs_size      = number
  }))
  default = {
    "vm1" = {
      ami           = "ami-04e601abe3e1a910f"
      instance_type = "t2.micro"
      ebs_size      = 8
    }
    ### Example for multiple VMs
    # "vm2" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "t2.micro"
    #   ebs_size      = 2
    # }
  }
}

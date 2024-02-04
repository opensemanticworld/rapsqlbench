# /* 
#    Copyright 2023 Andreas Raeder, https://github.com/raederan
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
# */

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
    "vm50k" = {
      ami           = "ami-04e601abe3e1a910f"
      instance_type = "r5.8xlarge"
      ebs_size      = 100
    }
    # "vm250k" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "r5.8xlarge"
    #   ebs_size      = 250
    # }
    # "vm125m" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "r5.8xlarge"
    #   ebs_size      = 600
    # }
    # "vm250m" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "r5.8xlarge"
    #   ebs_size      = 600
    # }
    # "vm500m" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "r5.8xlarge"
    #   ebs_size      = 2400
    # }
    # "vm1bn" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "r5.8xlarge"
    #   ebs_size      = 4800
    # }
    # "vm125my2" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "r5.8xlarge"
    #   ebs_size      = 600
    # }
    # "vm250my1" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "r5.8xlarge"
    #   ebs_size      = 1200
    # }
    # "vm250my2" = {
    #   ami           = "ami-04e601abe3e1a910f"
    #   instance_type = "r5.8xlarge"
    #   ebs_size      = 1200
    # }


    
  }
}



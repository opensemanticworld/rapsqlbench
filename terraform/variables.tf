# Provider Reference
variable "aws_region" {
  type    = string
  default = "eu-central-1" # Change this to your region
}

# Availability Zone Reference
variable "aws_availability_zone" {
  type    = string
  default = "eu-central-1a" # Change this to your availability zone
}

variable "aws_profile" {
  type    = string
  default = "sysarch-profile" # Change this to your profile name from sso session
}

# Enviorenment Reference
variable "env_tag" {
  type    = string
  default = "tf-aws-rapsqlbench"
}

# # SSH Key Reference
# variable "ssh_key_name" {
#   type    = string
#   default = "default-rsa-key" # Change this to your ssh key name
# }


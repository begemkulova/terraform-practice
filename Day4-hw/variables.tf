variable "subnet1_cidr" {
  description = "CIDR block for Subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet2_cidr" {
  description = "CIDR block for Subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ami_filter" {
  description = "AMI filter to use for EC2 instance"
  type        = string
  default     = "amzn2-ami-hvm-*-x86_64-gp2"
}

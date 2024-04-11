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


resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}


resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet1_cidr
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet2_cidr
  availability_zone = "us-east-1b"
}


data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = [var.ami_filter]
  }
  owners = ["amazon"]
}


resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet2.id
}


output "instance_id" {
  value       = aws_instance.my_instance.id
  description = "ID of the EC2 instance"
}

output "subnet_ids" {
  value       = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  description = "IDs of the subnets"
}

output "vpc_id" {
  value       = aws_vpc.my_vpc.id
  description = "ID of the VPC"
}

output "vpc_cidr_block" {
  value       = aws_vpc.my_vpc.cidr_block
  description = "CIDR block of the VPC"
}

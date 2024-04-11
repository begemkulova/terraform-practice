# Day3 hw
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

provider "aws" {
  region = "us-west-2" 
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet1_cidr
  availability_zone = "us-west-2a" 
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet2_cidr
  availability_zone = "us-west-2b" 
}

resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet2.id
  depends_on    = [aws_subnet.subnet1] # makng sure that subnet1 is created before launching instance
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = [var.ami_filter]
  }
  owners = ["amazon"]
}

resource "aws_internet_gateway" "public_gw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_gw.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnet1.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "private"
  }
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
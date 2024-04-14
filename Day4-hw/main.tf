# Day4 hw - ONLY VIRGINIA (without tax)
locals {
  subnet1_cidr = "10.0.1.0/24"
  subnet2_cidr = "10.0.2.0/24"
  ami_filter   = "amzn2-ami-hvm-*-x86_64-gp2"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "vpc-bekaiym"
    Owner = "Bekaiym"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.subnet1_cidr
  availability_zone = "us-east-1a"
  
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "subnet1"
    Type  = "public"
    Owner = "Bekaiym"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.subnet2_cidr
  availability_zone = "us-east-1b"
  
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "subnet2"
    Type  = "private"
    Owner = "Bekaiym"
  }
}

resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet2.id
  depends_on    = [aws_subnet.subnet1] # making sure that subnet is created before launching instance
  
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "my_instance"
    Type  = "private"
    Owner = "Bekaiym"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  
  filter {
    name   = "name"
    values = [local.ami_filter]
  }
  
  owners = ["amazon"]
}

resource "aws_internet_gateway" "public_gw" {
  vpc_id = aws_vpc.vpc.id
  
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "public_gw"
    Type  = "public"
    Owner = "Bekaiym"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_gw.id
  }

  tags = {
    Name  = "public-rt"
    Type  = "public"
    Owner = "Bekaiym"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public.id
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.vpc.id

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

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "public_sg"
    Type  = "public"
    Owner = "Bekaiym"
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.private.id
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnet1.id
  
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "nat_gateway"
    Type  = "public"
    Owner = "Bekaiym"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "nat_eip"
    Type  = "public"
    Owner = "Bekaiym"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name  = "private-rt"
    Type  = "private"
    Owner = "Bekaiym"
  }

  lifecycle {
    create_before_destroy = true
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
  value       = aws_vpc.vpc.id
  description = "ID of the VPC"
}

output "vpc_cidr_block" {
  value       = aws_vpc.vpc.cidr_block
  description = "CIDR block of the VPC"
}

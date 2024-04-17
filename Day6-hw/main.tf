provider "aws" {
  region = terraform.workspace == "dev" ? "us-east-1" : terraform.workspace == "stage" ? "us-east-2" : "us-west-1"
}

terraform {
  required_version = ">= 0.13"

  backend "s3" {
    bucket         = "bekaiym-s3-tf-virginia"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
  }
}

resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  count            = terraform.workspace == "prod" ? 1 : 0
  name             = "terraform-state-lock"
  billing_mode     = "PROVISIONED" #FreeTier
  read_capacity    = 5            #FreeTier
  write_capacity   = 5            #FreeTier
  hash_key         = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
}

locals {
  subnet1_cidr = "10.0.1.0/24"
  subnet2_cidr = "10.0.2.0/24"
  ami_filter   = "amzn2-ami-hvm-*-x86_64-gp2"
}

resource "aws_vpc" "vpc" {
  count      = terraform.workspace == "prod" ? 1 : 0
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
  count             = terraform.workspace == "prod" ? 2 : 0
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.subnet1_cidr
  availability_zone = "us-east-1${substr("abcd", count.index, 1)}" #count meta-argument

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "subnet1-${count.index + 1}"
    Type  = "public"
    Owner = "Bekaiym"
  }
}

resource "aws_instance" "public_instance" {
  count = terraform.workspace == "prod" ? length(aws_subnet.subnet1) : 0
  for_each = {
    for idx, subnet in aws_subnet.subnet1 : idx => subnet
  } # for each meta-argument
  ami             = data.aws_ami.amazon_linux.id
  instance_type   = "t2.micro"
  subnet_id       = each.value.id
  depends_on      = [aws_subnet.subnet1] # making sure that subnet is created before launching instance

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "public_instance-${each.key}"
    Type  = "public"
    Owner = "Bekaiym"
  }
}

resource "aws_subnet" "subnet2" {
  count             = terraform.workspace == "prod" ? 2 : 0
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.subnet2_cidr
  availability_zone = "us-east-1${substr("abcd", count.index, 1)}" # count meta-argument

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "subnet2-${count.index + 1}"
    Type  = "private"
    Owner = "Bekaiym"
  }
}

resource "aws_instance" "private_instance" {
  count = terraform.workspace == "prod" ? length(aws_subnet.subnet2) : 0
  for_each = {
    for idx, subnet in aws_subnet.subnet2 : idx => subnet
  } # for each meta-argument
  ami             = data.aws_ami.amazon_linux.id
  instance_type   = "t2.micro"
  subnet_id       = each.value.id
  depends_on      = [aws_subnet.subnet2] # making sure that subnet is created before launching instance

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "private_instance-${each.key}"
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
  count = terraform.workspace == "prod" ? 1 : 0
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
  count = terraform.workspace == "prod" ? 1 : 0
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
  count      = terraform.workspace == "prod" ? 1 : 0
  subnet_id = aws_subnet.subnet1[0].id
  route_table_id = aws_route_table.public.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "public_sg" {
  count = terraform.workspace == "prod" ? 1 : 0
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
  count      = terraform.workspace == "prod" ? 1 : 0
  subnet_id = aws_subnet.subnet2[0].id
  route_table_id = aws_route_table.private[0].id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count = terraform.workspace == "prod" ? 1 : 0
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnet1[0].id

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
  count = terraform.workspace == "prod" ? 1 : 0
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
  count   = terraform.workspace == "prod" ? 2 : 0
  vpc_id  = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name  = "private-rt-${count.index + 1}"
    Type  = "private"
    Owner = "Bekaiym"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "instance_id" {
  value = {
    for idx, instance in aws_instance.public_instance : idx => instance.id
  }
  description = "ID of the EC2 instances"
}

output "subnet_ids" {
  value       = [aws_subnet.subnet1[*].id, aws_subnet.subnet2[*].id]
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

output "current_workspace" {
  value       = terraform.workspace
  description = "Current workspace"
}


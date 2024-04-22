provider "aws" {
  region = terraform.workspace == "prod" ? "us-east-1" : terraform.workspace == "stage" ? "us-east-2" : "us-west-1"
}

terraform {
  backend "s3" {
    bucket = "bekaiym-s3-tf-virginia"
    key    = "networking/terraform.tfstate"
    region = "us-east-1"
    # dynamodb_table = "terraform-state-lock"
  }
}

resource "aws_vpc" "vpc" {
  count      = terraform.workspace == "prod" ? 1 : 0
  cidr_block = var.vpc_cidr_block

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "vpc-bekaiym"
    Owner = "Bekaiym"
  }
}


resource "aws_subnet" "public_subnets" {
  count             = terraform.workspace == "prod" ? 3 : 0
  vpc_id            = aws_vpc.vpc[0].id # Directly reference the first element in the tuple
  cidr_block        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"][count.index]
  availability_zone = "us-east-1${substr("abcd", count.index, 1)}" # count meta-argument

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "public_subnet-${count.index + 1}"
    Type  = "public"
    Owner = "Bekaiym"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = terraform.workspace == "prod" ? 3 : 0
  vpc_id            = aws_vpc.vpc[0].id # Directly reference the first element in the tuple
  cidr_block        = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"][count.index]
  availability_zone = "us-east-1${substr("abcd", count.index, 1)}" # count meta-argument

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "private_subnet-${count.index + 1}"
    Type  = "private"
    Owner = "Bekaiym"
  }
}

#################################################
output "vpc_id" {
  value       = aws_vpc.vpc[*].id
  description = "ID of the VPC"
}


output "public_subnet_ids" {
  value       = aws_subnet.public_subnets[*].id
  description = "IDs of the public subnets"
}

output "private_subnet_ids" {
  value       = aws_subnet.private_subnets[*].id
  description = "IDs of the private subnets"
}

# output "security_group_ids" {
#   value       = aws_security_group.compute_security_groups[*].id
#   description = "IDs of the security groups"
# }



#################################################
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

##################################################
# data "terraform_remote_state" "compute" {
#   backend = "s3"
#   config = {
#     bucket = "bekaiym-s3-tf-virginia"
#     key    = "env:/prod/compute/terraform.tfstate"
#     region = "us-east-1"
#   }
# }

# output "security_group_ids" {
#   value = module.compute.data.terraform_remote_state.networking.outputs.security_group_ids
# }




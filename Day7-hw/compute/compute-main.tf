provider "aws" {
  region = terraform.workspace == "prod" ? "us-east-1" : terraform.workspace == "stage" ? "us-east-2" : "us-west-1"
}

# terraform {
#   backend "s3" {
#     bucket = "bekaiym-s3-tf-virginia"
#     key    = "compute/terraform.tfstate"
#     region = "us-east-1"
#     # dynamodb_table = "terraform-state-lock"
#   }
# }

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "bekaiym-s3-tf-virginia"
    key    = "env:/prod/networking/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "compute_instances" {
  count = terraform.workspace == "prod" ? 3 : 0

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = data.terraform_remote_state.networking.outputs.public_subnet_ids[count.index]

  security_groups = [aws_security_group.compute_security_groups[count.index].id]


  tags = {
    Name  = "compute_instance-${count.index + 1}"
    Type  = "compute"
    Owner = "Bekaiym"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "compute_security_groups" {
  count  = terraform.workspace == "prod" ? 3 : 0
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id[0] # Access the first element in the tuple

  dynamic "ingress" {
    for_each = count.index == 0 ? [22] : count.index == 1 ? [80] : [22, 80, 443]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
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
    Name  = "compute_sg-${count.index + 1}"
    Type  = "compute"
    Owner = "Bekaiym"
  }
}

###################################
output "instance_ids" {
  value       = aws_instance.compute_instances[*].id
  description = "IDs of the EC2 instances"
}

output "compute_security_group_ids" {
  value       = aws_security_group.compute_security_groups[*].id
  description = "IDs of the security groups"
}




###################################
variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t2.micro"
}

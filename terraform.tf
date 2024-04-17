terraform {
  required_version = ">= 0.13"

  backend "s3" {
    bucket         = "bekaiym-s3-tf-virginia"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
  }
}

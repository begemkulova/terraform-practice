terraform {
  required_version = ">= 0.13"

  backend "s3" {
    bucket         = "bekaiym-s3-terraform"
    key            = "terraform.tfstate"
    region         = "us-east-2"

    # Use the DynamoDB table created above
    dynamodb_table = "terraform-state-lock"
  }
}
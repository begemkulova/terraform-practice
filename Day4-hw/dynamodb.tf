resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name             = "terraform-state-lock"
  billing_mode     = "PROVISIONED" #FreeTier
  read_capacity    = 5 #FreeTier
  write_capacity   = 5 #FreeTier
  hash_key         = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
}
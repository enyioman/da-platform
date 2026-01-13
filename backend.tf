terraform {
  backend "s3" {
    bucket         = "dals-language-terraform-state" # Replace with your bucket
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dals-language-terraform-state-lock"
    encrypt        = true
  }
}
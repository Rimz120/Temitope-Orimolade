terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # For a personal lab, local state is fine. If you want to mirror how your
  # team likely does it, swap this for an S3 backend with DynamoDB locking.
  # backend "s3" {
  #   bucket         = "your-tfstate-bucket"
  #   key            = "aurora-groupid-lab/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

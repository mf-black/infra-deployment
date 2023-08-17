terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      version = ">=3.72.0"
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {
    region         = "eu-west-1"
    bucket         = "tf-state-378075579141-test"
    key            = "test.tfstate"
    dynamodb_table = "tf-state-lock-test"
    encrypt        = "true"
  }
}

provider "aws" {
  region = "eu-west-1"

}
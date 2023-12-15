terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # A single bucket can store state from multiple projects, they differ on the `key` value.
    bucket         = "xvr-tfstate"
    key            = "my-app-name.tfstate"
    encrypt        = true
    region         = "us-east-1"
    dynamodb_table = "tfstate-locks"
    # Enable state locking and consistency checking via a Dynamo DB table. A single table can hold multiple remote state files.
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current" {}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

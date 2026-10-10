terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "openar-cloud-sandbox"
      Owner     = var.owner
      ManagedBy = "opentofu"
      ExpiresIn = "${var.max_lifetime_hours}h"
    }
  }
}

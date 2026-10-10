terraform {
  required_version = ">= 1.6"

  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# The API token is read from the LINODE_TOKEN environment variable.
provider "linode" {}

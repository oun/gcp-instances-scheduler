terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0, < 6"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.1, < 4.0"
    }
  }
}
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0, < 6"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 1.2, < 3.0"
    }
  }
}
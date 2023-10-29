terraform {
  required_version = ">= 0.13"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0, < 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 1.2, < 3.0"
    }
  }
}
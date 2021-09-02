terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.9"
    }
  }

  required_version = ">= 0.13.7"
}

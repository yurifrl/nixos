terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_api_token
}

# Get current public IPv4 automatically
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

locals {
  my_ip = sensitive(trimspace(data.http.my_ip.response_body))
}

# Use existing VPC Network
data "digitalocean_vpc" "default" {
  name = "default-nyc1"
}

# Variables
variable "digitalocean_api_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh_key_fingerprint" {
  description = "SSH key fingerprint"
  type        = string
}

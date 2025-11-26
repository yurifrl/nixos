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

# Get current public IP automatically
data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
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

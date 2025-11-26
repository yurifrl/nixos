# Get latest NixOS Foundry image name dynamically
data "external" "latest_foundry_image" {
  program = ["${path.module}/../scripts/get-latest-image", "foundry"]
}

# Reference the latest custom NixOS Foundry image
data "digitalocean_image" "nixos_foundry" {
  name = data.external.latest_foundry_image.result.image_name
}

# Firewall
resource "digitalocean_firewall" "foundry" {
  name = "foundry-firewall"

  droplet_ids = [digitalocean_droplet.foundry.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["${local.my_ip}/32"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Volume
resource "digitalocean_volume" "foundry_data" {
  region                  = "nyc1"
  name                    = "foundry-data"
  size                    = 50 # GB
  initial_filesystem_type = "ext4"
  description             = "Foundry data volume"
}

# Droplet
resource "digitalocean_droplet" "foundry" {
  name   = "digitalocean-foundry-01"
  region = "nyc1"
  size   = "s-1vcpu-512mb-10gb"
  image  = data.digitalocean_image.nixos_foundry.id

  vpc_uuid = data.digitalocean_vpc.default.id

  volume_ids = [digitalocean_volume.foundry_data.id]

  ssh_keys = [var.ssh_key_fingerprint]

  tags = ["foundry", "nixos"]
}

# Outputs
output "foundry_droplet_ip" {
  value     = digitalocean_droplet.foundry.ipv4_address
  sensitive = true
}

output "foundry_droplet_private_ip" {
  value     = digitalocean_droplet.foundry.ipv4_address_private
  sensitive = true
}

output "foundry_volume_id" {
  value = digitalocean_volume.foundry_data.id
}

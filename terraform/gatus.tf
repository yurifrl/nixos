# Get latest NixOS Gatus image name dynamically
data "external" "latest_gatus_image" {
  program = ["${path.module}/../scripts/get-latest-image", "gatus"]
}

# Reference the latest custom NixOS Gatus image
data "digitalocean_image" "nixos_gatus" {
  name = data.external.latest_gatus_image.result.image_name
}

# Firewall for gatus
resource "digitalocean_firewall" "gatus" {
  name = "gatus-firewall"

  droplet_ids = [digitalocean_droplet.gatus.id]

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

# Volume for gatus
resource "digitalocean_volume" "gatus_data" {
  region                  = "nyc1"
  name                    = "gatus-data"
  size                    = 50 # GB
  initial_filesystem_type = "ext4"
  description             = "Gatus data volume"
}

# Droplet for gatus
resource "digitalocean_droplet" "gatus" {
  name   = "digitalocean-gatus-01"
  region = "nyc1"
  size   = "s-1vcpu-512mb-10gb"
  image  = data.digitalocean_image.nixos_gatus.id

  vpc_uuid = data.digitalocean_vpc.default.id

  volume_ids = [digitalocean_volume.gatus_data.id]

  ssh_keys = [var.ssh_key_fingerprint]

  tags = ["gatus", "nixos"]
}

# Outputs
output "gatus_droplet_ip" {
  value     = digitalocean_droplet.gatus.ipv4_address
  sensitive = true
}

output "gatus_droplet_private_ip" {
  value     = digitalocean_droplet.gatus.ipv4_address_private
  sensitive = true
}

output "gatus_volume_id" {
  value = digitalocean_volume.gatus_data.id
}

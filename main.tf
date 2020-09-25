
# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

# Add main ssh key
resource "hcloud_ssh_key" "default" {
  name       = "main ssh key"
  public_key = file("${var.private_ssh_key_path}.pub")
}

# Create a server
resource "hcloud_server" "node1" {
  name        = "node1"
  image       = "ubuntu-16.04"
  ssh_keys    = [hcloud_ssh_key.default.name]
  server_type = "cx11"
}


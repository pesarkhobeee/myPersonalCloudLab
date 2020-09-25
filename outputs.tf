output "public_ip4" {
  value = "${hcloud_server.node1.ipv4_address}"
}

output "status" {
  value = "${hcloud_server.node1.status}"
}

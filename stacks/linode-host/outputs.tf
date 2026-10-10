output "public_ip" {
  value = one(linode_instance.sandbox.ipv4)
}

output "ssh" {
  value = "ssh root@${one(linode_instance.sandbox.ipv4)}"
}

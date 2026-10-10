output "public_ip" {
  value = aws_instance.sandbox.public_ip
}

output "ssh" {
  value = "ssh ubuntu@${aws_instance.sandbox.public_ip}"
}

output "expires_after_hours" {
  value = var.max_lifetime_hours
}

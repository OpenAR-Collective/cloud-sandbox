resource "random_password" "root" {
  length  = 32
  special = true
}

resource "linode_instance" "sandbox" {
  label  = var.name
  region = var.region
  type   = var.instance_type
  image  = "linode/ubuntu24.04"
  tags   = ["openar-cloud-sandbox"]

  # The API requires a root password. Key login is the only one used in practice,
  # and the password is random and never printed.
  root_pass       = random_password.root.result
  authorized_keys = [var.ssh_public_key]

  metadata {
    user_data = base64encode(templatefile("${path.module}/../../shared/cloud-init.yaml", {
      ssh_user = "root"
      # A powered-off Linode still bills, so no shutdown timer here.
      # Teardown is `tofu destroy`. See docs/cost-guardrails.md.
      lifetime_minutes = 0
    }))
  }
}

resource "linode_firewall" "sandbox" {
  label           = "${var.name}-fw"
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
  linodes         = [linode_instance.sandbox.id]

  inbound {
    label    = "ssh-from-operator"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = [var.allowed_ssh_cidr]
  }
}

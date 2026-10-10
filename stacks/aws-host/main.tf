data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_key_pair" "sandbox" {
  key_name_prefix = "${var.name}-"
  public_key      = var.ssh_public_key
}

resource "aws_security_group" "sandbox" {
  name_prefix = "${var.name}-"
  description = "SSH from one address only. No other inbound."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from the operator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "sandbox" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.sandbox.key_name
  vpc_security_group_ids = [aws_security_group.sandbox.id]

  # Shutting down from inside the host terminates it, so the timer below
  # ends the billing and not just the CPU.
  instance_initiated_shutdown_behavior = "terminate"

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_gb
    delete_on_termination = true
    encrypted             = true
  }

  user_data = templatefile("${path.module}/../../shared/cloud-init.yaml", {
    ssh_user         = "ubuntu"
    lifetime_minutes = var.max_lifetime_hours * 60
  })

  user_data_replace_on_change = true

  tags = {
    Name = var.name
  }
}

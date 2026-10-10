variable "region" {
  description = "Linode region ID, such as us-east or us-ord."
  type        = string
  default     = "us-east"
}

variable "name" {
  description = "Short name for this run, such as benchmark-run-2."
  type        = string
  default     = "sandbox"
}

variable "instance_type" {
  description = "Use a Dedicated CPU plan for benchmarks. Shared CPU plans have noisy neighbors."
  type        = string
  default     = "g6-dedicated-8" # 8 dedicated CPUs, 16 GB
}

variable "ssh_public_key" {
  description = "Contents of your SSH public key."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Your public IPv4 address as a /32, such as 203.0.113.7/32."
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0)) && var.allowed_ssh_cidr != "0.0.0.0/0"
    error_message = "Give a specific CIDR block. 0.0.0.0/0 is not allowed."
  }
}

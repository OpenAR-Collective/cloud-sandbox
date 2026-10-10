variable "region" {
  description = "AWS region to build in."
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "Who is responsible for this host. Shows up in the cost tags."
  type        = string
}

variable "name" {
  description = "Short name for this run, such as benchmark-run-2."
  type        = string
  default     = "sandbox"
}

variable "instance_type" {
  description = "Use a fixed-performance type for benchmarks, never a burstable t-type. The default has 16 vCPUs, 64 GB, and local NVMe. For a network-disk comparison use m7i.4xlarge."
  type        = string
  default     = "m6id.4xlarge"
}

variable "root_volume_gb" {
  description = "Size of the root disk, in GB. Allow 100 for benchmark images, data, and results."
  type        = number
  default     = 100
}

variable "max_lifetime_hours" {
  description = "Dead-man switch. The host shuts itself down after this many hours, and AWS terminates it on shutdown."
  type        = number
  default     = 12
}

variable "ssh_public_key" {
  description = "Contents of your SSH public key, for example the output of: cat ~/.ssh/id_ed25519.pub"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Your public address as a /32, such as 203.0.113.7/32. There is deliberately no default."
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0)) && var.allowed_ssh_cidr != "0.0.0.0/0"
    error_message = "Give a specific CIDR block. 0.0.0.0/0 is not allowed."
  }
}

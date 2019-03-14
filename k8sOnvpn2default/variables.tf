
variable "region1" {
  description = "Region 1"
  default     = "us-central1"
}

variable "region2" {
  description = "Region 2"
  default     = "us-central1"
}

variable "default-range" {
  description = "Default IP range on VPC"
  default     = "10.128.0.0/20"
}

variable "region2-range" {
  description = "Default IP range for new network"
  default     = "10.7.0.0/24"
}

variable "vpn-network" {
  description = "VPN Network name"
  default     = "k8s-network"
}

variable "vpn-subnetwork" {
  description = "Default IP range for new network"
  default     = "subnet-k8s"
}

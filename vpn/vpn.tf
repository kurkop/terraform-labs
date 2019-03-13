provider "google" {
  credentials = "${file("~/gce/account.json")}"
  project     = "${var.project}"
  region      = "${var.region1}"
}

# 1. Adding networks
resource "google_compute_subnetwork" "subnet-a" {
  name          = "subnet-a"
  ip_cidr_range = "10.5.4.0/24"
  region        = "${var.region1}"
  network       = "${google_compute_network.vpn-network-1.self_link}"
}

resource "google_compute_network" "vpn-network-1" {
  name       = "vpn-network-1"
  auto_create_subnetworks = false
}


resource "google_compute_subnetwork" "subnet-b" {
  name          = "subnet-b"
  ip_cidr_range = "10.1.3.0/24"
  region        = "${var.region2}"
  network       = "${google_compute_network.vpn-network-2.self_link}"
}

resource "google_compute_network" "vpn-network-2" {
  name       = "vpn-network-2"
  auto_create_subnetworks = false
}

# 2. Adding ssh and icmp rules

resource "google_compute_firewall" "allow-icmp-ssh-network-1" {
  name          = "allow-icmp-ssh-network-1"
  network       = "${google_compute_network.vpn-network-1.name}"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow-icmp-ssh-network-2" {
  name          = "allow-icmp-ssh-network-2"
  network       = "${google_compute_network.vpn-network-2.name}"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  allow {
    protocol = "icmp"
  }
}

# 3. Create gateways
resource "google_compute_vpn_gateway" "target_gateway1" {
  name    = "vpn-1"
  network = "${google_compute_network.vpn-network-1.self_link}"
  region  = "${var.region1}"
}

resource "google_compute_vpn_gateway" "target_gateway2" {
  name    = "vpn-2"
  network = "${google_compute_network.vpn-network-2.self_link}"
  region  = "${var.region2}"
}

# 4. Reserve static ips
resource "google_compute_address" "vpn_1_static_ip" {
  name   = "vpn-1-static-ip"
  region = "${var.region1}"
}

resource "google_compute_address" "vpn_2_static_ip" {
  name   = "vpn-2-static-ip"
  region = "${var.region2}"
}

# 5. Create forwarding rules for both vpn gateways
resource "google_compute_forwarding_rule" "fr1_esp" {
  name        = "vpn-1-esp"
  region      = "${var.region1}"
  ip_protocol = "ESP"
  ip_address  = "${google_compute_address.vpn_1_static_ip.address}"
  target      = "${google_compute_vpn_gateway.target_gateway1.self_link}"
}

resource "google_compute_forwarding_rule" "vpn_2_esp" {
  name        = "vpn-2-esp"
  region      = "${var.region2}"
  ip_protocol = "ESP"
  ip_address  = "${google_compute_address.vpn_2_static_ip.address}"
  target      = "${google_compute_vpn_gateway.target_gateway2.self_link}"
}

resource "google_compute_forwarding_rule" "vpn_1_udp500" {
  name        = "vpn-1-udp500"
  region      = "${var.region1}"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = "${google_compute_address.vpn_1_static_ip.address}"
  target      = "${google_compute_vpn_gateway.target_gateway1.self_link}"
}

resource "google_compute_forwarding_rule" "vpn_2_udp500" {
  name        = "vpn-2-udp500"
  region      = "${var.region2}"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = "${google_compute_address.vpn_2_static_ip.address}"
  target      = "${google_compute_vpn_gateway.target_gateway2.self_link}"
}

resource "google_compute_forwarding_rule" "vpn_1_udp4500" {
  name        = "fr1-udp4500"
  region      = "${var.region1}"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = "${google_compute_address.vpn_1_static_ip.address}"
  target      = "${google_compute_vpn_gateway.target_gateway1.self_link}"
}

resource "google_compute_forwarding_rule" "vpn_2_udp4500" {
  name        = "vpn-2-udp4500"
  region      = "${var.region2}"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = "${google_compute_address.vpn_2_static_ip.address}"
  target      = "${google_compute_vpn_gateway.target_gateway2.self_link}"
}

# 6. Create tunnels
resource "google_compute_vpn_tunnel" "tunnel1" {
  name               = "tunnel1to2"
  region             = "${var.region1}"
  ike_version = "2"
  peer_ip            = "${google_compute_address.vpn_2_static_ip.address}"
  shared_secret      = "Ibq2x0kM8rIvHr"
  target_vpn_gateway = "${google_compute_vpn_gateway.target_gateway1.self_link}"
  local_traffic_selector = ["0.0.0.0/0"]
  remote_traffic_selector = ["0.0.0.0/0"]

  depends_on = [
    "google_compute_forwarding_rule.vpn_1_udp500",
    "google_compute_forwarding_rule.vpn_1_udp4500",
    "google_compute_forwarding_rule.fr1_esp",
  ]
}

resource "google_compute_vpn_tunnel" "tunnel2" {
  name               = "tunnel2"
  region             = "${var.region2}"
  ike_version = "2"
  peer_ip            = "${google_compute_address.vpn_1_static_ip.address}"
  shared_secret      = "Ibq2x0kM8rIvHr"
  target_vpn_gateway = "${google_compute_vpn_gateway.target_gateway2.self_link}"
  local_traffic_selector = ["0.0.0.0/0"]
  remote_traffic_selector = ["0.0.0.0/0"]

  depends_on = [
    "google_compute_forwarding_rule.vpn_2_udp500",
    "google_compute_forwarding_rule.vpn_2_udp4500",
    "google_compute_forwarding_rule.vpn_2_esp",
  ]
}

# 7. Create static routes
resource "google_compute_route" "route1to2" {
  name                = "route1to2"
  network             = "${google_compute_network.vpn-network-1.name}"
  next_hop_vpn_tunnel = "${google_compute_vpn_tunnel.tunnel1.self_link}"
  dest_range          = "${google_compute_subnetwork.subnet-b.ip_cidr_range}"
  priority            = 1000
}

resource "google_compute_route" "route2" {
  name                = "route2to1"
  network             = "${google_compute_network.vpn-network-2.name}"
  next_hop_vpn_tunnel = "${google_compute_vpn_tunnel.tunnel2.self_link}"
  dest_range          = "${google_compute_subnetwork.subnet-a.ip_cidr_range}"
  priority            = 1000
}

# 8. Create instances
resource "google_compute_instance" "instance1" {
    machine_type = "f1-micro"
    name = "server-1"
    zone = "us-east1-b"

    network_interface {
      subnetwork = "${google_compute_subnetwork.subnet-a.name}"
      access_config {
        // Ephemeral IP
      }
    }

    boot_disk {
      initialize_params {
        image = "debian-cloud/debian-9"
      }
    }
}

resource "google_compute_instance" "instance2" {
    machine_type = "f1-micro"
    name = "server-2"
    zone = "europe-west1-b"

    network_interface {
      subnetwork = "${google_compute_subnetwork.subnet-b.name}"
      access_config {
        // Ephemeral IP
      }
    }

    boot_disk {
      initialize_params {
        image = "debian-cloud/debian-9"
      }
    }
}

resource "google_container_node_pool" "jobs-np" {
  name       = "jobs"
  zone       = "${var.region2}-c"
  cluster    = "${google_container_cluster.kube_cluster.name}"
  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 10
  }

  node_config {
    machine_type     = "n1-highcpu-8"
    min_cpu_platform = "Intel Skylake"
    labels {
      type = "scripts"
    }
  }
}

resource "google_container_cluster" "kube_cluster" {
  name               = "test"
  zone               = "${var.region2}-c"
  initial_node_count = "1"

  network            = "${var.vpn-network}"
  subnetwork         = "${var.vpn-subnetwork}"

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  ip_allocation_policy {
    subnetwork_name = "${var.vpn-subnetwork}"
  }



  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  node_config {
    machine_type = "n1-standard-1"
    min_cpu_platform = "Intel Skylake"
  }
}

## Ops manager to director
resource "google_compute_firewall" "pcf-allow-director" {
  name    = "${var.env_name}-allow-director"
  network = "${google_compute_network.pcf-network.name}"

  allow {
    protocol = "all"
  }

  source_ranges = ["10.0.6.0/24"]
}

# Allow HTTP/S access to Ops Manager from the outside world
resource "google_compute_firewall" "ops-manager-external" {
  name        = "${var.env_name}-ops-manager-external"
  network     = "${google_compute_network.pcf-network.name}"
  target_tags = ["${var.env_name}-ops-manager-external"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }
}

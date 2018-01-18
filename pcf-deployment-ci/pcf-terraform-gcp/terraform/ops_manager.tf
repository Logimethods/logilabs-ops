


#resource "google_compute_address" "ops-manager-ip" {
#  name = "${var.env_name}-ops-manager-ip"
#}

resource "google_compute_instance" "ops-manager" {
  name           = "${var.env_name}-ops-manager"
  machine_type   = "${var.opsman_machine_type}"
  zone           = "${element(var.zones, 1)}"
  create_timeout = 10
  tags           = ["${var.env_name}-ops-manager-external"]

  boot_disk {
    initialize_params {
      image = "projects/pivotal-lab/global/images/pcf-meetup-ops-manager-image"
      size  = 150
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.management-subnet.name}"

    access_config {
      nat_ip = "35.229.24.116"
    }
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  metadata = {
    block-project-ssh-keys = "FALSE"
  }
}



provider "google" {
  project     = "${var.project}"
  region      = "${var.region}"
}
ssl_cert="${ssl_cert}"
ssl_cert_private_key="${private_key}"

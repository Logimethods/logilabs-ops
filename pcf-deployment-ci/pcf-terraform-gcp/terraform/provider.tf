provider "google" {
  credentials = "${file("account.json")}"
  project     = "pivotal-lab"
  region      = "us-east1"
}

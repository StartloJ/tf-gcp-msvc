# resource "google_compute_instance" "openvpn" {
#   name         = "openvpn-example"
#   machine_type = "f1-micro"
#   zone         = local.available_zones[1]

#   boot_disk {
#     initialize_params {
#       image = "ubuntu-os-cloud/ubuntu-2204-lts"
#     }
#   }

#   network_interface {
#     network = module.example_main_vpc.network_name
#     access_config {
#       nat_ip = google_compute_address.openvpn_ip.address
#     }
#   }

#   metadata = {
#     startup-script = file("scripts/openvpn.sh")
#   }

#   service_account {
#     email = google_service_account.openvpn.email
#     scopes = [
#       "https://www.googleapis.com/auth/cloud-platform",
#     ]
#   }
# }

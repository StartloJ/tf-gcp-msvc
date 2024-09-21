/******************************************
        Firewall example
 *****************************************/
module "example_firewall" {
  source = "../../modules/networks/firewall-rules"

  project_id   = data.google_project.example.project_id
  network_name = module.example_main_vpc.network_name

  ingress_rules = [
    {
      name               = "allow-ingress-ssh"
      description        = "Public SSH rule for example project"
      direction          = "INGRESS"
      destination_ranges = ["0.0.0.0/0"]
      source_ranges      = ["0.0.0.0/0"]
      priority           = 100
      allow = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
    },
    {
      name               = "allow-ingress-http-https"
      description        = "Public HTTP rule for example project"
      direction          = "INGRESS"
      destination_ranges = ["0.0.0.0/0"]
      source_ranges      = ["0.0.0.0/0"]
      priority           = 110
      allow = [
        {
          protocol = "tcp"
          ports    = ["80", "443"]
        }
      ]
    }
  ]

  egress_rules = [
    {
      name               = "allow-egress-default"
      description        = "Public Egress rule for example project"
      direction          = "EGRESS"
      destination_ranges = ["0.0.0.0/0"]
      source_ranges      = ["0.0.0.0/0"]
      priority           = 65535
      allow = [
        {
          protocol = "all"
        }
      ]
    }
  ]
}
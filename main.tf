provider "google" {
  project = var.project-id   #replace this with your project-id
  region  = var.region
  zone    = var.zone
}

### NETWORK
data "google_compute_network" "default" {
  name                    = "default"
}

## SUBNET
resource "google_compute_subnetwork" "subnet-1" {
  name                     = var.subnet-name
  ip_cidr_range            = var.subnet-cidr
  network                  = data.google_compute_network.default.self_link
  region                   = var.region
  private_ip_google_access = var.private_google_access
}

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = data.google_compute_network.default.self_link

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000", "22"]
  }

  source_tags = ["web"]
}

### COMPUTE
## NGINX PROXY
resource "google_compute_instance" "nginx_instance" {
  name         = "nginx-proxy"
  machine_type = environment_machine_type[var.target_environment]
  labels = {
    environmet = environment_map[var.target_environment]
  }
  tags = ["web"]
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.subnet-1.self_link
    access_config {
      
    }
  }
}

resource "google_compute_instance" "web-instances" {
  count = 3
  name         = "web${count.index}"
  machine_type = "f1-micro"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.subnet-1.self_link
  }
}


## WEB1
#resource "google_compute_instance" "web1" {
#  name         = "web1"
#  machine_type = "f1-micro"
#  
#  boot_disk {
#    initialize_params {
#      image = "debian-cloud/debian-11"
#    }
#  }
#
#  network_interface {
#    # A default network is created for all GCP projects
#    network = data.google_compute_network.default.self_link
#    subnetwork = google_compute_subnetwork.subnet-1.self_link
#  }
#}
## WEB2
#resource "google_compute_instance" "web2" {
#  name         = "web2"
#  machine_type = "f1-micro"
#  
#  boot_disk {
#    initialize_params {
#      image = "debian-cloud/debian-11"
#    }
#  }
#
#  network_interface {
#    network = data.google_compute_network.default.self_link
#    subnetwork = google_compute_subnetwork.subnet-1.self_link
#  }
#}
## WEB3
#resource "google_compute_instance" "web3" {
#  name         = "web3"
#  machine_type = "f1-micro"
#  
#  boot_disk {
#    initialize_params {
#      image = "debian-cloud/debian-11"
#    }
#  }
#
#  network_interface {
#    network = data.google_compute_network.default.self_link
#    subnetwork = google_compute_subnetwork.subnet-1.self_link
#  }  
#}

## DB
#resource "google_compute_instance" "mysqldb" {
#  name         = "mysqldb"
#  machine_type = "f1-micro"
#  
#  boot_disk {
#    initialize_params {
#      image = "debian-cloud/debian-11"
#    }
#  }
#
#  network_interface {
#    network = data.google_compute_network.default.self_link
#    subnetwork = google_compute_subnetwork.subnet-1.self_link
#  }  
#}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

## Cloud SQL
resource "google_sql_database_instance" "cloudsql" {
  name = "web-app-db-${random_id.db_name_suffix.hex}"
  database_version = "MYSQL_8_0"
  region = "us-central1"

  settings {
    tier = "db-f1-micro"
  }
  deletion_protection = false
}

## CLOUD SQL USER
resource "google_sql_user" "users" {
  name = var.dbusername
  instance = google_sql_database_instance.cloudsql.name
  password = var.dbpassword
}
/**
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

provider "google" {
  project = var.project
}

provider "google-beta" {
  project = var.project
}

resource "google_compute_network" "default" {
  name                    = var.network_name
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "group1" {
  name                     = var.network_name
  ip_cidr_range            = "10.125.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.group1_region
  private_ip_google_access = true
}

# Router and Cloud NAT are required for installing packages from repos (apache, php etc)
resource "google_compute_router" "group1" {
  name    = "${var.network_name}-gw-group1"
  network = google_compute_network.default.self_link
  region  = var.group1_region
}

module "cloud-nat-group1" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 5.0"
  router     = google_compute_router.group1.name
  project_id = var.project
  region     = var.group1_region
  name       = "${var.network_name}-cloud-nat-group1"
}

resource "google_compute_subnetwork" "group2" {
  name                     = var.network_name
  ip_cidr_range            = "10.126.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.group2_region
  private_ip_google_access = true
}

# Router and Cloud NAT are required for installing packages from repos (apache, php etc)
resource "google_compute_router" "group2" {
  name    = "${var.network_name}-gw-group2"
  network = google_compute_network.default.self_link
  region  = var.group2_region
}

module "cloud-nat-group2" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 5.0"
  router     = google_compute_router.group2.name
  project_id = var.project
  region     = var.group2_region
  name       = "${var.network_name}-cloud-nat-group2"
}

resource "google_compute_subnetwork" "group3" {
  name                     = var.network_name
  ip_cidr_range            = "10.127.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.group3_region
  private_ip_google_access = true
}

# Router and Cloud NAT are required for installing packages from repos (apache, php etc)
resource "google_compute_router" "group3" {
  name    = "${var.network_name}-gw-group3"
  network = google_compute_network.default.self_link
  region  = var.group3_region
}

module "cloud-nat-group3" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 5.0"
  router     = google_compute_router.group3.name
  project_id = var.project
  region     = var.group3_region
  name       = "${var.network_name}-cloud-nat-group3"
}

resource "random_id" "assets-bucket" {
  prefix      = "terraform-static-content-"
  byte_length = 2
}

locals {
  health_check = {
    request_path = "/"
    port         = 80
  }
}

# [START cloudloadbalancing_ext_http_gce_plus_bucket]
module "gce-lb-https" {
  source  = "terraform-google-modules/lb-http/google"
  version = "~> 10.0"
  name    = var.network_name
  project = var.project
  target_tags = [
    "${var.network_name}-group1",
    module.cloud-nat-group1.router_name,
    "${var.network_name}-group2",
    module.cloud-nat-group2.router_name,
    "${var.network_name}-group3",
    module.cloud-nat-group3.router_name
  ]
  firewall_networks = [google_compute_network.default.self_link]
  url_map           = google_compute_url_map.ml-bkd-ml-mig-bckt-s-lb.self_link
  create_url_map    = false
  ssl               = true
  create_ssl_certificate = true
  managed_ssl_certificate_domains = ["example.com"]
  private_key       = tls_private_key.example.private_key_pem
  certificate       = tls_self_signed_cert.example.cert_pem
  

  backends = {
    default = {
      protocol    = "HTTP"
      port        = 80
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = false

      health_check = local.health_check
      log_config = {
        enable      = true
        sample_rate = 1.0
      }
      groups = [
        {
          group = module.mig1.instance_group
        },
        {
          group = module.mig2.instance_group
        },
        {
          group = module.mig3.instance_group
        },
      ]

      iap_config = {
        enable = false
      }
    }

    mig1 = {
      protocol    = "HTTP"
      port        = 80
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = false

      health_check = local.health_check
      log_config = {
        enable      = true
        sample_rate = 1.0
      }
      groups = [
        {
          group = module.mig1.instance_group
        },
      ]

      iap_config = {
        enable = false
      }
    }

    mig2 = {
      protocol    = "HTTP"
      port        = 80
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = false

      health_check = local.health_check
      log_config = {
        enable      = true
        sample_rate = 1.0
      }
      groups = [
        {
          group = module.mig2.instance_group
        },
      ]

      iap_config = {
        enable = false
      }
    }

    mig3 = {
      protocol    = "HTTP"
      port        = 80
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = false

      health_check = local.health_check
      log_config = {
        enable      = true
        sample_rate = 1.0
      }
      groups = [
        {
          group = module.mig3.instance_group
        },
      ]

      iap_config = {
        enable = false
      }
    }
  }
}

resource "google_compute_url_map" "ml-bkd-ml-mig-bckt-s-lb" {
  // note that this is the name of the load balancer
  name            = var.network_name
  default_service = module.gce-lb-https.backend_services["default"].self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = module.gce-lb-https.backend_services["default"].self_link

    path_rule {
      paths = [
        "/group1",
        "/group1/*"
      ]
      service = module.gce-lb-https.backend_services["mig1"].self_link
    }

    path_rule {
      paths = [
        "/group2",
        "/group2/*"
      ]
      service = module.gce-lb-https.backend_services["mig2"].self_link
    }

    path_rule {
      paths = [
        "/group3",
        "/group3/*"
      ]
      service = module.gce-lb-https.backend_services["mig3"].self_link
    }

    path_rule {
      paths = [
        "/assets",
        "/assets/*"
      ]
      service = google_compute_backend_bucket.assets.self_link
    }
  }
}

resource "google_compute_backend_bucket" "assets" {
  name        = random_id.assets-bucket.hex
  description = "Contains static resources for example app"
  bucket_name = google_storage_bucket.assets.name
  enable_cdn  = true
}

resource "google_storage_bucket" "assets" {
  name     = random_id.assets-bucket.hex
  location = "US"

  // delete bucket and contents on destroy.
  force_destroy = true
}

// The image object in Cloud Storage.
// Note that the path in the bucket matches the paths in the url map path rule above.
resource "google_storage_bucket_object" "image" {
  name         = "assets/gcp-logo.svg"
  content      = file("gcp-logo.svg")
  content_type = "image/svg+xml"
  bucket       = google_storage_bucket.assets.name
}

// Make object public readable.
resource "google_storage_object_acl" "image-acl" {
  bucket         = google_storage_bucket.assets.name
  object         = google_storage_bucket_object.image.name
  predefined_acl = "publicRead"
}
# [END cloudloadbalancing_ext_http_gce_plus_bucket]
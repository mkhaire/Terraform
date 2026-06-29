terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

# 1. The Core Shared VPC Network
resource "google_compute_network" "vpc" {
  name                    = "vpc-${var.environment}"
  project                 = var.host_project_id
  auto_create_subnetworks = false
}

# 2. Shared VPC Activation
resource "google_compute_shared_vpc_host_project" "host" {
  project = var.host_project_id
}

# 3. Dynamic Subnet Generation for the Applications
resource "google_compute_subnetwork" "app_subnets" {
  for_each      = { for app in var.apps : app.name => app }
  name          = "sb-${var.environment}-${each.value.name}"
  project       = var.host_project_id
  region        = var.region
  network       = google_compute_network.vpc.id
  # Math: Generates distinct /24 ranges from your /15 environment supernet
  ip_cidr_range = cidrsubnet(var.environment_supernet, 9, each.value.id) 
}

# 4. Global Network Firewall Policy for Folder Micro-Segmentation
resource "google_compute_network_firewall_policy" "policy" {
  name    = "fp-${var.environment}-app-isolation"
  project = var.host_project_id
}

resource "google_compute_network_firewall_policy_association" "association" {
  name              = "assoc-${var.environment}"
  project           = var.host_project_id
  firewall_policy   = google_compute_network_firewall_policy.policy.name
  attachment_target = google_compute_network.vpc.id
}

# Dynamic Rule Engine: Loops through all 44 apps to only allow matching application IDs
resource "google_compute_network_firewall_policy_rule" "app_cross_env_allow" {
  for_each        = { for app in var.apps : app.name => app }
  project         = var.host_project_id
  firewall_policy = google_compute_network_firewall_policy.policy.name
  
  description     = "Allow cross-env traffic from DEV/QA/BETA for ${each.value.name} matching subnets"
  direction       = "INGRESS"
  disabled        = false
  priority        = 1000 + each.value.id
  action          = "allow"

  match {
    layer4_config {
      ip_protocol = "all"
    }
    # Dynamic Math: Derives the matching subnet range of the SAME app ID from other environment tiers
    src_ip_ranges = [
      cidrsubnet("10.10.0.0/15", 9, each.value.id), # DEV equivalent subnet
      cidrsubnet("10.12.0.0/15", 9, each.value.id), # QA equivalent subnet
      cidrsubnet("10.14.0.0/15", 9, each.value.id)  # BETA equivalent subnet
    ]
  }
}

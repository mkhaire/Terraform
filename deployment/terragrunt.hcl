locals {
  # Automatically load organization matrix variables
  common_vars = yamldecode(file(find_in_parent_folders("common_apps.yaml")))
}

# Dynamically generate the backend configuration across all folders
remote_state {
  backend = "gcs"
  config = {
    bucket   = "org-enterprise-tfstate-bucket"
    prefix   = "${path_relative_to_include()}/terraform.tfstate"
    project  = "core-network-transit-project"
    location = "asia-south1"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Dynamically inject global provider parameter definitions
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "google" {
  region      = "asia-south1"
}
EOF
}

# Pass common variables down to all child infrastructure objects
inputs = {
  apps = local.common_vars.apps
}

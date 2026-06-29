# Inherit root backend configurations
include "root" {
  path = find_in_parent_folders()
}

# Extract environment-specific configurations (supernets, tags)
include "env" {
  path   = find_in_parent_folders("environment.hcl")
  expose = true
}

# Point directly to the local modules folder blueprint
terraform {
  source = "../../../../modules//shared_vpc_host"
}

# Set execution inputs for the shared vpc host module
inputs = {
  host_project_id      = "shared-vpc-dev-host-project"
  environment          = include.env.locals.environment
  environment_supernet = include.env.locals.environment_supernet
}

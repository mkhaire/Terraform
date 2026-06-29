variable "host_project_id" { type = string }
variable "environment" { type = string }
variable "region" { type = string; default = "asia-south1" }
variable "environment_supernet" { type = string }
variable "apps" {
  type = list(object({
    name = string
    id   = number
  }))
}

#######################################################################################
#     Providers
########################################################################################
# Define providers and set versions
terraform {
  required_version = ">= 0.14.0" # Takes into account Terraform versions from 0.14.0
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 2.0.0"
    }
    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.45.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 1.39.0"
    }
    dns = {
      version = "~> 3.3.2"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.0"
    }
  }
}

# Configure the OpenStack provider hosted by OVHcloud
provider "openstack" {
  auth_url         = "https://auth.cloud.ovh.net/v3/" # Authentication URL
  domain_name      = "Default"                        # Domain name - Always at 'default' for OVHcloud
  user_domain_name = "Default"
  user_name        = ovh_cloud_project_user.user.username
  password         = ovh_cloud_project_user.user.password
  region           = var.openstack_region
  tenant_id        = var.ovh_public_cloud_project_id
}

provider "grafana" {
  url = "https://${openstack_networking_floatingip_v2.tf_lb_floatingip.address}:${openstack_lb_listener_v2.graf_listener.protocol_port}"
  # This is requested because the cert is issued for the database.cloud.ovh.net domain
  insecure_skip_verify = true
  org_id               = "3"
  auth                 = "${ovh_cloud_project_database_user.avnadmin.name}:${ovh_cloud_project_database_user.avnadmin.password}"
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

########################################################################################
#     User
########################################################################################
resource "ovh_cloud_project_user" "user" {
  service_name = var.ovh_public_cloud_project_id
  description  = "User created by terraform loadbalancer script"
  role_name    = "administrator"
} 
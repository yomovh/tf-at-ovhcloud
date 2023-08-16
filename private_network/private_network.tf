########################################################################################
# This script creates an S3 bucket along with 1 S3 user
#
# It requires the following variables to be defined for the OVH provider :
# OVH_ENDPOINT
# OVH_APPLICATION_KEY
# OVH_APPLICATION_SECRET
# OVH_CONSUMER_KEY
# The following is required specifically for this script:
# TF_VAR_OVH_PUBLIC_CLOUD_PROJECT_ID that shall be filled with your public cloud project id or it will be requested on script startup
# TF_VAR_VRACK_ID with a vrack id to which the cloud project will be attached or it will be requested on script startup
########################################################################################


########################################################################################
#     Variables
########################################################################################
variable "ovh_public_cloud_project_id" {
  type = string
}

variable "vrack_id" {
  type        = string
  description = "the vrack_id pn_xxxxxxx"
}

variable "openstack_region" {
  type    = string
  default = "GRA9"
}

variable "user_desc_prefix" {
  type    = string
  default = "[TF] User created by s3 terraform script"
}

variable "vlan_id" {
  type    = number
  default = "42"
}


#######################################################################################
#     Providers
########################################################################################
terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.50"
    }

    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.28"
    }
  }
}
# Configure the OpenStack expoprovider hosted by OVHcloud
provider "openstack" {
  auth_url         = "https://auth.cloud.ovh.net/v3/" # Authentication URL
  domain_name      = "Default"                        # Domain name - Always at 'default' for OVHcloud
  user_domain_name = "Default"
  user_name        = ovh_cloud_project_user.user.username
  password         = ovh_cloud_project_user.user.password
  region           = var.openstack_region
  tenant_id        = var.ovh_public_cloud_project_id
}

########################################################################################
#     User / Credential
########################################################################################
resource "ovh_cloud_project_user" "user" {
  service_name = var.ovh_public_cloud_project_id
  description  = "${var.user_desc_prefix} that is used to manage network"
  role_name    = "network_operator"
}

########################################################################################
#     Network
########################################################################################
resource "ovh_vrack_cloudproject" "vcp" {
  service_name = var.vrack_id
  project_id   = var.ovh_public_cloud_project_id
}

resource "openstack_networking_network_v2" "tf_network" {
  name           = "tf_network"
  admin_state_up = "true"
  value_specs = {
    "provider:network_type"    = "vrack"
    "provider:segmentation_id" = var.vlan_id
  }

}

resource "openstack_networking_subnet_v2" "tf_subnet" {
  name        = "tf_subnet"
  network_id  = openstack_networking_network_v2.tf_network.id
  cidr        = "10.0.0.0/16"
  enable_dhcp = true
}


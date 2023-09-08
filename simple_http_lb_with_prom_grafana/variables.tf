
variable "ovh_public_cloud_project_id" {
  type        = string
  description = "the id of your public cloud project. It can be found on the upper left in OVHCloud Control Plane below your project name"
}

variable "openstack_region" {
  type        = string
  description = "the openstack region on which the infrastructure will be deployed. You can view the openstack regions in the OVHCloud Control Plane in the 'Quotas and Regions' panel "
  default     = "GRA11"
}

variable "dns_subdomain" {
  type        = string
  description = "the subdomain below  the zone"
  default     = "lbdemo"
}

variable "dns_zone" {
  type        = string
  description = "the zone that will be used to host the sub domain"
}

variable "resource_prefix" {
  type        = string
  description = "the prefix that is used for all the  created resources"
  default     = "tf_lb_with_prom_and_grafana_"
}
variable "image_name" {
  type        = string
  description = "The image used for the instances"
  default     = "Ubuntu 22.04"
}
variable "instance_type" {
  type        = string
  description = "the instances type"
  default     = "d2-2"
}
variable "external_network" {
  type        = string
  description = "The name of the network that is used to connect a private network to internet. This should normally not be changed"
  default     = "Ext-Net"
}

variable "instance_nb" {
  type        = number
  description = "The number of http instance that will be answering to http requests behind the load balancer"
  default     = 2
}

variable "prometheus_version" {
  type        = string
  description = "The version of prometheus that is downloaded and installed"
  default     = "2.37.8"
}
variable "acme_disable_complete_propagation" {
  type        = bool
  description = "Disable the propagation of the ACME Let's Encrypt DNS challenge"
  default     = "false"
}

variable "acme_email_address" {
  type        = string
  description = "The email adresse used in the ACME Let's Encrypt process "
}

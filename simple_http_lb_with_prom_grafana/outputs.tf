########################################################################################
#     Outputs
########################################################################################
output "lb_url" {
  value = "https://${var.dns_subdomain}.${var.dns_zone}"
  description = "The loadbalancer public url"
}


output "grafana_url" {
  value = "https://${var.dns_subdomain}.${var.dns_zone}:${openstack_lb_listener_v2.graf_listener.protocol_port}/dashboards"
  description = "Grafana url"
  
}
output "grafana_user" {
  value = "${ovh_cloud_project_database_user.avnadmin.name}"
}

output "grafana_password" {
  value = "${ovh_cloud_project_database_user.avnadmin.password}"
  sensitive = true
}

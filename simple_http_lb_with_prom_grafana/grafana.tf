########################################################################################
#     Grafana
########################################################################################
resource "ovh_cloud_project_database" "grafana" {
  service_name = var.ovh_public_cloud_project_id
  description  = "${var.resource_prefix}grafana"
  engine       = "grafana"
  version      = "10.0"
  plan         = "essential"

  flavor = "db1-4"
  nodes {
    region     = substr(var.openstack_region, 0, 3)
    network_id = openstack_networking_network_v2.tf_lb_network.id
    subnet_id  = openstack_networking_subnet_v2.tf_lb_subnet.id
  }
}
resource "ovh_cloud_project_database_ip_restriction" "iprestriction" {
  service_name = var.ovh_public_cloud_project_id
  engine       = ovh_cloud_project_database.grafana.engine
  cluster_id   = ovh_cloud_project_database.grafana.id
  ip           = openstack_networking_subnet_v2.tf_lb_subnet.cidr
}

data "dns_a_record_set" "grafana" {
  host = ovh_cloud_project_database.grafana.endpoints[0].domain
  depends_on = [
    ovh_cloud_project_database.grafana
  ]
}

resource "grafana_data_source" "prometheus" {
  type = "prometheus"
  name = "prom"
  url  = "http://${openstack_compute_instance_v2.prometheus.access_ip_v4}:9090"
}

resource "grafana_dashboard" "octavia_dashboard" {
  config_json = file("resources/octavia-amphora-load-balancer_rev1.json")
}

resource "ovh_cloud_project_database_user" "avnadmin" {
  service_name = var.ovh_public_cloud_project_id
  engine       = ovh_cloud_project_database.grafana.engine
  cluster_id   = ovh_cloud_project_database.grafana.id
  name         = "avnadmin"
}


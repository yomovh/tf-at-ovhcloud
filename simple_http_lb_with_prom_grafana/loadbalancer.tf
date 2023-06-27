
########################################################################################
#     Loadbalancers
########################################################################################
resource "openstack_lb_loadbalancer_v2" "tf_lb" {
  name           = "${var.resource_prefix}_lb"
  vip_network_id = openstack_networking_network_v2.tf_lb_network.id
  vip_subnet_id  = openstack_networking_subnet_v2.tf_lb_subnet.id
}


resource "openstack_lb_listener_v2" "http_listener" {
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.tf_lb.id
}

resource "openstack_lb_listener_v2" "https_listener" {
  protocol                  = "TERMINATED_HTTPS"
  protocol_port             = 443
  loadbalancer_id           = openstack_lb_loadbalancer_v2.tf_lb.id
  default_tls_container_ref = openstack_keymanager_secret_v1.tls_secret.secret_ref
}

#second listener to expose grafana
resource "openstack_lb_listener_v2" "graf_listener" {
  protocol        = "HTTPS"
  protocol_port   = 8443
  loadbalancer_id = openstack_lb_loadbalancer_v2.tf_lb.id
}

resource "openstack_lb_listener_v2" "prom_listener" {
  protocol        = "PROMETHEUS"
  protocol_port   = 8088
  loadbalancer_id = openstack_lb_loadbalancer_v2.tf_lb.id
  #restrict the access of the listener to the private network subnet
  allowed_cidrs = [openstack_networking_subnet_v2.tf_lb_subnet.cidr]
}


resource "openstack_lb_pool_v2" "main_pool" {
  name        = "${var.resource_prefix}main_pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.https_listener.id
}

resource "openstack_lb_pool_v2" "graf_pool" {
  name        = "${var.resource_prefix}graf_pool"
  protocol    = "HTTPS"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.graf_listener.id

}

resource "openstack_lb_l7policy_v2" "redirect_http_policy" {
  name         = "redirect_http_policy"
  action       = "REDIRECT_TO_URL"
  position     = 1
  listener_id  = openstack_lb_listener_v2.http_listener.id
  redirect_url = "https://${var.dns_subdomain}.${var.dns_zone}"
}

resource "openstack_lb_l7rule_v2" "redirect_http_rule" {
  l7policy_id  = openstack_lb_l7policy_v2.redirect_http_policy.id
  type         = "PATH"
  compare_type = "STARTS_WITH"
  value        = "/"
}
resource "openstack_lb_monitor_v2" "monitor_1" {
  pool_id     = openstack_lb_pool_v2.main_pool.id
  type        = "HTTP"
  url_path    = "/index.html"
  delay       = 5
  timeout     = 10
  max_retries = 4
}

resource "openstack_lb_member_v2" "main_member" {
  count         = var.instance_nb
  name          = "member_${count.index}"
  pool_id       = openstack_lb_pool_v2.main_pool.id
  address       = openstack_compute_instance_v2.http_server[count.index].access_ip_v4
  protocol_port = 80
  subnet_id     = openstack_networking_subnet_v2.tf_lb_subnet.id
}

resource "openstack_lb_member_v2" "graf_member" {
  name          = "graf_member"
  pool_id       = openstack_lb_pool_v2.graf_pool.id
  address       = data.dns_a_record_set.grafana.addrs[0]
  protocol_port = 443
  subnet_id     = openstack_networking_subnet_v2.tf_lb_subnet.id
}

resource "ovh_domain_zone_record" "record" {
  zone      = var.dns_zone
  subdomain = var.dns_subdomain
  fieldtype = "A"
  ttl       = "3600"
  target    = openstack_networking_floatingip_v2.tf_lb_floatingip.address
}
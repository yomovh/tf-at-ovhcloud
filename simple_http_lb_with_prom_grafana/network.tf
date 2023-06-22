########################################################################################
#     Network
########################################################################################
data "openstack_networking_network_v2" "ext_net" {
  name     = var.external_network
  external = true
  depends_on = [
    ovh_cloud_project_user.user
  ]
}

resource "openstack_networking_network_v2" "tf_lb_network" {
  name = "${var.resource_prefix}network"
  admin_state_up = "true"
}


resource "openstack_networking_subnet_v2" "tf_lb_subnet"{
  name       = "${var.resource_prefix}subnet"
  network_id = openstack_networking_network_v2.tf_lb_network.id
  cidr       = "10.0.0.0/24"
  gateway_ip = "10.0.0.254"
  dns_nameservers = ["1.1.1.1", "1.0.0.1"]
  ip_version = 4

}

resource "openstack_networking_router_v2" "tf_lb_router" {
  name                = "${var.resource_prefix}router"
  external_network_id = data.openstack_networking_network_v2.ext_net.id
}
  
resource "openstack_networking_floatingip_v2" "tf_lb_floatingip" {
  pool = data.openstack_networking_network_v2.ext_net.name
}

resource "openstack_networking_router_interface_v2" "tf_lb_router_itf_priv" {
  router_id = openstack_networking_router_v2.tf_lb_router.id
  subnet_id = openstack_networking_subnet_v2.tf_lb_subnet.id
}

resource "openstack_networking_floatingip_associate_v2" "association" {
  floating_ip     = openstack_networking_floatingip_v2.tf_lb_floatingip.address
  port_id         = openstack_lb_loadbalancer_v2.tf_lb.vip_port_id
} 
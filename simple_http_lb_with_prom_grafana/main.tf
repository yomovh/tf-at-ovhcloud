########################################################################################
#     User
########################################################################################
resource "ovh_cloud_project_user" "user" {
  service_name = var.ovh_public_cloud_project_id
  description = "User created by terraform loadbalancer script"
  role_name = "administrator"
} 

########################################################################################
#     Instances
########################################################################################


# Creating the instance, no SSH keys 
resource "openstack_compute_instance_v2" "http_server" {
  count = var.instance_nb
  name      = "${var.resource_prefix}http_server_${count.index}" # Instance name
  image_name  = var.image_name # Image name
  flavor_name = var.instance_type # Instance type name
  network {
    name      = "${openstack_networking_network_v2.tf_lb_network.name}"
  }
  user_data = <<EOF
#!/bin/bash
echo 'user data begins'
sudo apt-get update
sudo apt-get install -y nginx
echo '<html><head><title>Load Balanced Member 1</title></head><body><h1>You did it ! You hit your OVHCloud load balancer member #${count.index} ! </p></body></html>' | sudo tee /var/www/html/index.html
echo 'user data end'
EOF
  # Add dependency on router itf to be sure the instance can access internet to retrieve package in user data
  depends_on = [openstack_networking_router_interface_v2.tf_lb_router_itf_priv]
}

resource "openstack_compute_instance_v2" "prometheus" {
  name      = "${var.resource_prefix}prometheus" # Instance name
  image_name  = var.image_name # Image name
  flavor_name = var.instance_type # Instance type name
  //key_pair = openstack_compute_keypair_v2.keypair.name
  network {
    name      = openstack_networking_network_v2.tf_lb_network.name
  }
  user_data = <<EOF
#!/bin/bash
su - ubuntu
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v${var.prometheus_version}/prometheus-${var.prometheus_version}.linux-amd64.tar.gz
tar xzvf prometheus-${var.prometheus_version}.linux-amd64.tar.gz
cd prometheus-${var.prometheus_version}.linux-amd64
echo "  - job_name: octavia
    static_configs:
      - targets: ['${openstack_lb_loadbalancer_v2.tf_lb.vip_address}:${openstack_lb_listener_v2.prom_listener.protocol_port}']" >> prometheus.yml
./prometheus --config.file=prometheus.yml&
EOF
  # Add dependency on router itf to be sure the instance can access internet to retrieve package in user data
  depends_on = [openstack_networking_router_interface_v2.tf_lb_router_itf_priv]
}

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

########################################################################################
#     Loadbalancers
########################################################################################
resource "openstack_lb_loadbalancer_v2" "tf_lb" {
  name        = "${var.resource_prefix}_lb"
  vip_network_id  = "${openstack_networking_network_v2.tf_lb_network.id}"
  vip_subnet_id = "${openstack_networking_subnet_v2.tf_lb_subnet.id}"
}


resource "openstack_lb_listener_v2" "http_listener" {
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.tf_lb.id
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
  name = "${var.resource_prefix}main_pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.http_listener.id

}

resource "openstack_lb_pool_v2" "graf_pool" {
  name = "${var.resource_prefix}graf_pool"
  protocol    = "HTTPS"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.graf_listener.id

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
  subnet_id     = "${openstack_networking_subnet_v2.tf_lb_subnet.id}"
}

resource "openstack_lb_member_v2" "graf_member" {
  name          = "graf_member"         
  pool_id       = openstack_lb_pool_v2.graf_pool.id
  address       = data.dns_a_record_set.grafana.addrs[0]
  protocol_port = 443
  subnet_id     = "${openstack_networking_subnet_v2.tf_lb_subnet.id}"
}


########################################################################################
#     Grafana
########################################################################################
resource "ovh_cloud_project_database" "grafana" {
  service_name = var.ovh_public_cloud_project_id
  description   = "${var.resource_prefix}-grafana"
  engine        = "grafana"
  version       = "9.1"
  plan          = "essential"
  
  flavor        = "db1-4"
  nodes {
    region = substr(var.openstack_region, 0, 3)
    network_id = openstack_networking_network_v2.tf_lb_network.id
    subnet_id = openstack_networking_subnet_v2.tf_lb_subnet.id
  }
}
resource "ovh_cloud_project_database_ip_restriction" "iprestriction" {
  service_name = var.ovh_public_cloud_project_id
  engine       = ovh_cloud_project_database.grafana.engine
  cluster_id   = ovh_cloud_project_database.grafana.id
  ip           = openstack_networking_subnet_v2.tf_lb_subnet.cidr
}

data "dns_a_record_set" "grafana" {
  host=ovh_cloud_project_database.grafana.endpoints[0].domain
  depends_on = [
    ovh_cloud_project_database.grafana
  ]
}

resource "grafana_data_source" "prometheus" {
  type = "prometheus"
  name = "prom"
  url = "http://${openstack_compute_instance_v2.prometheus.access_ip_v4}:9090"
}

resource "grafana_dashboard" "octavia_dashboard"{
  config_json = file("resources/octavia-amphora-load-balancer_rev1.json")
}

resource "ovh_cloud_project_database_user" "avnadmin" {
  service_name = var.ovh_public_cloud_project_id
  engine       = ovh_cloud_project_database.grafana.engine
  cluster_id   = ovh_cloud_project_database.grafana.id
  name = "avnadmin"
}
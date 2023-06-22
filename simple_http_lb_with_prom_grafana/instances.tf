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
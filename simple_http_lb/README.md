# Description 

**This simple HTTP load balancer does not use HTTPS which is standard nowadays. This choice was made to simplify this sample. If you need an HTTPS, please open an issue**

This example creates:
- an openstack user that will be used to create the whole infrastructure
- a private network
- a Floating IP and a virtual router (that is used a Public Gateway to manage egress & ingress  from / to the private network)
- an HTTP load balancer
- 2 HTTP servers (the number of HTTP server can changed using the `instance_nb` variable) 
- optionally if a `stream_id` is set, the [log_subscription](https://registry.terraform.io/providers/ovh/ovh/latest/docs/resources/cloud_project_region_loadbalancer_log_subscription) is created so that you can see your HTTP logs in your Log Data Platform instance !

The output of the `terraform apply` will provide the public ip of your load balancer. Open it in a browser and hit reload to see the round robin in action !

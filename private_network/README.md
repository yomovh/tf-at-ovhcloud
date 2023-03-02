# Pre requisites
- same as the one described in the root [README.md](../README.md)
- a vrack has been created in the control panel. You can create up to 4.000 VLANs inside a vrack. The vrack id will be requested when `terraform apply`

# Example description
This example creates:
- one openstack user to be able to manage the network
- a link between the vrack and the public cloud project
- a private network with the specified VLAN ID
- a subnet inside that network
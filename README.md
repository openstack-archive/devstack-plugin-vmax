# devstack-plugin-vmax
This plugin enables the VMAX backend for cinder. For each backend, it creates the required xml file, populating said file along with cinder.conf with the appropriate values

# Enabling in devstack
* Add this repo as an external repository to localrc::

     [[local|localrc]]</br>
     enable_plugin devstack-plugin-vmax https://github.com/openstack/devstack-plugin-vmax ocata

* For each vmax backend in CINDER_ENABLED_BACKENDS above, append the
configuration details to localrc as shown below for VMAX_Backend_1. Contact
your Storage Admin for your parameters::

    VMAX_Backend_1_EcomServerIp=<insert_ip_address></br>
    VMAX_Backend_1_EcomServerPort=<Ecom_port_number></br>
    VMAX_Backend_1_EcomUserName=<Ecom_username></br>
    VMAX_Backend_1_EcomPassword=<Ecom_password></br>
    VMAX_Backend_1_Array=<Array_to_use></br>
    VMAX_Backend_1_Pool=<storage_resource_pool></br>
    VMAX_Backend_1_WORKLOAD=<work_load></br>
    VMAX_Backend_1_SLO=<Service_level></br>
    VMAX_Backend_1_PortGroup1=<port_group></br>
    VMAX_Backend_1_PortGroup2=<port_group></br>
    VMAX_Backend_1_StorageProtocol=<Storage_protocol>

* run "stack.sh"

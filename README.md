# Rocky

# devstack-plugin-vmax
This plugin enables the POWERMAX backend for cinder. For each backend, it creates the required xml file, populating said file along with cinder.conf with the appropriate values

# Enabling in devstack
* Add this repo as an external repository to localrc::

     [[local|localrc]]</br>
     enable_plugin devstack-plugin-vmax https://github.com/openstack/devstack-plugin-vmax

* For each powermax cinder backend to be used in the devstack setup, add the
backend name to the enabled backends in localrc as shown below. Backend name
 has to start with POWERMAX::

    [[local|localrc]]</br>
    CINDER_ENABLED_BACKENDS=powermax:POWERMAX_Backend_1,powermax:POWERMAX_Backend_2

* For each vmax backend in CINDER_ENABLED_BACKENDS above, append the
configuration details to localrc as shown below for POWERMAX_Backend_1. Contact
your Storage Admin for your parameters::

    POWERMAX_Backend_1_RestServerIp=<insert_ip_address></br>
    POWERMAX_Backend_1_RestServerPort=<Rest_port_number></br>
    POWERMAX_Backend_1_RestUserName=<Rest_password></br>
    POWERMAX_Backend_1_Array=<Array_to_use></br>
    POWERMAX_Backend_1_SRP=<storage_resource_pool></br>
    POWERMAX_Backend_1_WORKLOAD=<work_load></br>
    POWERMAX_Backend_1_SLO=<Service_level></br>
    POWERMAX_Backend_1_SSLVerify=<pem_file_for_ssl_verification></br>
    POWERMAX_Backend_1_PortGroup1=<port_group></br>
    POWERMAX_Backend_1_PortGroup2=<port_group></br>
    POWERMAX_Backend_1_StorageProtocol=<Storage_protocol>

* run "stack.sh"

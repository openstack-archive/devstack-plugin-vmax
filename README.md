# devstack-plugin-vmax
This plugin enables the VMAX backend for cinder. For each backend, it creates the required xml file, populating said file along with cinder.conf with the appropriate values

# Enabling in devstack
* Add this repo as an external repository to localrc::

     [[local|localrc]]</br>
     enable_plugin devstack-plugin-vmax https://github.com/okpoyu/devstack-plugin-vmax

* For each vmax cinder backend to be used in the devstack setup add the
backend name to the enabled backends in localrc as shown below. Backend name
 has to start with VMAX
    [[local|localrc]]</br>
    CINDER_ENABLED_BACKENDS=vmax:VMAX_Backend_1,vmax:VMAX_Backend_2

* For each vmax backend in CINDER_ENABLED_BACKENDS above, append the
configuration details to localrc as shown below for VMAX_Backend_1. Contact
your Storage Admin for your parameters.
    VMAX_Backend_1_RestServerIp=<insert_ip_address></br>
    VMAX_Backend_1_RestServerPort=<Rest_port_number></br>
    VMAX_Backend_1_RestUserName=<Rest_password></br>
    VMAX_Backend_1_Array=<Array_to_use></br>
    VMAX_Backend_1_SRP=<insert_ip_address></br>
    VMAX_Backend_1_WORKLOAD=<Workload></br>
    VMAX_Backend_1_SLO=<Service_level></br>
    VMAX_Backend_1_SSLVerify=<pem_file_for_ssl_verification></br>
    VMAX_Backend_1_PortGroup1=<port_group></br>
    VMAX_Backend_1_PortGroup2=<port_group></br>
    VMAX_Backend_1_StorageProtocol=<Storage_protocol>

* run "stack.sh"
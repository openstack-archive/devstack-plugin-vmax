# devstack-plugin-vmax
This plugin enables the VMAX backend for cinder. For each backend, it creates the required xml file, populating said file along with cinder.conf with the appropriate values

# Enabling in devstack
* Add this repo as an external repository to localrc::

     [[local|localrc]]</br>
     enable_plugin devstack-plugin-vmax https://github.com/okpoyu/devstack-plugin-vmax

* run "stack.sh"

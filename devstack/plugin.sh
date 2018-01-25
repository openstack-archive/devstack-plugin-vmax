#!/bin/bash

# devstack/plugin.sh
# Setup VMAX as backend for Devstack

function update_volume_type {
# Update volume types
    for be in ${CINDER_ENABLED_BACKENDS//,/ }; do
        be_name=${be##*:}
        be_type=${be%%:*}
        if [[ ${be_type} == "vmax" ]]; then
            array="${be_name}_Array"
            srp="${be_name}_SRP"
            slo="None"
            workload="None"
            pool_name=${!srp}+${!array}
            vmax_temp="${be_name}_WORKLOAD"
            if [  -n "${!vmax_temp}" ]; then
                workload="${be_name}_WORKLOAD"
                pool_name=${!workload}+${pool_name}
            else
                pool_name=${workload}+${pool_name}
            fi
            vmax_temp="${be_name}_SLO"
            if [  -n "${!vmax_temp}" ]; then
                slo="${be_name}_SLO"
                pool_name=${!slo}+${pool_name}
            else
                pool_name=${slo}+${pool_name}
            fi
            openstack volume type set --property pool_name="${pool_name}" \
            ${be_name}
        fi
    done
}

function configure_port_groups {
    local be_name=$1
    vmax_temp="${be_name}_PortGroup"
    dell_emc_portGroups=0
    for i in ${!VMAX*}; do
        temp1=${i##${vmax_temp}}
        if [[ "$temp1" == "$i" ]]; then
            continue
        fi
        arrIN=(${temp1//_/ })
        if [[ "${arrIN[0]}" -gt "$dell_emc_portGroups" ]]; then
            dell_emc_portGroups=${arrIN[0]}
        fi
    done
    pg_list="["
    for (( m=1 ; m<=dell_emc_portGroups ; m++ )) ; do
        vmax_temp="${be_name}_PortGroup${m}"
        pg_list="${pg_list}${!vmax_temp}"
        if (( m!=dell_emc_portGroups )) ; then
            pg_list="${pg_list},"
        fi
    done
    pg_list="${pg_list}]"
    iniset ${CINDER_CONF} ${be_name} vmax_port_groups ${pg_list}
}

function configure_single_pool {
    local be_name=$1
    configure_port_groups ${be_name}
    for val in "SSLVerify"  "Array" "SRP" "RestPassword" "RestUserName"\
    "RestServerPort" "RestServerIp" ; do
        vmax_temp="${be_name}_${val}"
        if [  -n "${!vmax_temp}" ]; then
            if [[ "${val}" == "RestServerIp" ]]; then
               iniset ${CINDER_CONF} ${be_name} san_ip ${!vmax_temp}
            elif [[ "${val}" == "RestServerPort" ]]; then
                iniset ${CINDER_CONF} ${be_name} san_rest_port ${!vmax_temp}
            elif [[ "${val}" == "RestUserName" ]]; then
                iniset ${CINDER_CONF} ${be_name} san_login ${!vmax_temp}
            elif [[ "${val}" == "RestPassword" ]]; then
                iniset ${CINDER_CONF} ${be_name} san_password ${!vmax_temp}
            elif [[ "${val}" == "Array" ]]; then
                iniset ${CINDER_CONF} ${be_name} vmax_array ${!vmax_temp}
            elif [[ "${val}" == "SRP" ]]; then
                iniset ${CINDER_CONF} ${be_name} vmax_srp ${!vmax_temp}
            elif [[ "${val}" == "SSLVerify" ]]; then
                if [[ "${!vmax_temp}" != "False" ]]; then
                    iniset ${CINDER_CONF} ${be_name} driver_ssl_cert_verify \
                    True
                    iniset ${CINDER_CONF} ${be_name} driver_ssl_cert_path \
                    ${!vmax_temp}
                fi
            fi
        fi
    done
}

function configure_cinder_backend_vmax {
    local be_name=$1
    local emc_multi=${be_name%%_*}

    configure_single_pool ${be_name}

    storage_proto="${be_name}_StorageProtocol"
    vmax_directory="cinder.volume.drivers.dell_emc.vmax."
    if [[ "${!storage_proto}" == "iSCSI" ]]; then
        iniset ${CINDER_CONF} ${be_name} volume_driver \
        "${vmax_directory}iscsi.VMAXISCSIDriver"
    fi
    if [ "${!storage_proto}" = "FC" ]; then
        iniset ${CINDER_CONF} ${be_name} volume_driver \
        "${vmax_directory}fc.VMAXFCDriver"
    fi
    iniset ${CINDER_CONF} ${be_name} volume_backend_name ${be_name}
}

if [[ "$1" == "stack" && "$2" == "pre-install" ]]; then
    # no-op
    :
elif [[ "$1" == "stack" && "$2" == "install" ]]; then
    # no-op
    :
elif [[ "$1" == "stack" && "$2" == "post-config" ]]; then
    # no-op
    :
elif [[ "$1" == "stack" && "$2" == "extra" ]]; then
    update_volume_type
elif [[ "$1" == "stack" && "$2" == "post-extra" ]]; then
    # no-op
    :
fi

if [[ "$1" == "unstack" ]]; then
    # no-op
    :
fi

if [[ "$1" == "clean" ]]; then
    # no-op
:
fi

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
    echo "<PortGroups>" >> \
        ${CINDER_CONF_DIR}/cinder_dell_emc_config_$be_name.xml
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
    for (( m=1 ; m<=dell_emc_portGroups ; m++ )) ; do
        vmax_temp="${be_name}_PortGroup${m}"
        echo "<PortGroup>${!vmax_temp}</PortGroup>" >> \
        ${CINDER_CONF_DIR}/cinder_dell_emc_config_${be_name}.xml
    done
    echo "</PortGroups>" >> \
        ${CINDER_CONF_DIR}/cinder_dell_emc_config_${be_name}.xml
}

function configure_single_pool {
    local be_name=$1
    for val in "RestServerIp" "RestServerPort" "RestUserName" "RestPassword"\
    "Array" "SRP" "SSLVerify" ; do
        vmax_temp="${be_name}_${val}"
        if [  -n "${!vmax_temp}" ]; then
            echo "<${val}>${!vmax_temp}</${val}>" >> \
            ${CINDER_CONF_DIR}/cinder_dell_emc_config_${be_name}.xml
        fi
    done
    configure_port_groups ${be_name}
}

function configure_cinder_backend_vmax {
    local be_name=$1
    local emc_multi=${be_name%%_*}
    iniset ${CINDER_CONF} ${be_name} volume_backend_name ${be_name}
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

    iniset ${CINDER_CONF} ${be_name} cinder_dell_emc_config_file \
    "$CINDER_CONF_DIR/cinder_dell_emc_config_$be_name.xml"

    touch ${CINDER_CONF_DIR}/cinder_dell_emc_config_${be_name}.xml
    echo "<?xml version='1.0' encoding='UTF-8'?>" > \
    ${CINDER_CONF_DIR}/cinder_dell_emc_config_${be_name}.xml
    echo "<EMC>" >> ${CINDER_CONF_DIR}/cinder_dell_emc_config_${be_name}.xml

    configure_single_pool ${be_name}

    echo "</EMC>" >> ${CINDER_CONF_DIR}/cinder_dell_emc_config_${be_name}.xml
    if [ ! -f "$CINDER_CONF_DIR/cinder_emc_config.xml" ]; then
        ln -s ${CINDER_CONF_DIR}/cinder_dell_emc_config_${be_name}.xml \
            ${CINDER_CONF_DIR}/cinder_emc_config.xml
    fi
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

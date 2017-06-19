#!/bin/bash

# devstack/plugin.sh
# Setup VMAX as backend for Devstack

function configure_port_groups {
    local be_name=$1
    echo "<PortGroups>" >> \
        ${CINDER_CONF_DIR}/cinder_emc_config_${be_name}.xml
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
        ${CINDER_CONF_DIR}/cinder_emc_config_${be_name}.xml
    done
    echo "</PortGroups>" >> \
        ${CINDER_CONF_DIR}/cinder_emc_config_${be_name}.xml
}

function configure_single_pool {
    local be_name=$1
    for val in "EcomServerIp" "EcomServerPort" "EcomUserName" "EcomPassword"\
    "Array" "Pool" "Retries" "Interval" "ServiceLevel" "Workload" "FastPolicy";
    do
        vmax_temp="${be_name}_${val}"
        if [  -n "${!vmax_temp}" ]; then
            echo "<${val}>${!vmax_temp}</${val}>" >> \
            ${CINDER_CONF_DIR}/cinder_emc_config_${be_name}.xml
        fi
    done
    vmax_temp="${be_name}_SLO"
    if [  -n "${!vmax_temp}" ]; then
        echo "<SLO>${!vmax_temp}</SLO>" >> \
        ${CINDER_CONF_DIR}/cinder_emc_config_${be_name}.xml
    fi
    configure_port_groups ${be_name}
}

function configure_cinder_backend_vmax {
    local be_name=$1
    iniset ${CINDER_CONF} ${be_name} volume_backend_name ${be_name}
    storage_proto="${be_name}_StorageProtocol"
    vmax_directory="cinder.volume.drivers.emc.emc_vmax_"
    if [[ "${!storage_proto}" == "iSCSI" ]]; then
        iniset ${CINDER_CONF} ${be_name} volume_driver \
        "${vmax_directory}iscsi.EMCVMAXISCSIDriver"
    fi
    if [ "${!storage_proto}" = "FC" ]; then
        iniset ${CINDER_CONF} ${be_name} volume_driver \
        "${vmax_directory}fc.EMCVMAXFCDriver"
    fi
    iniset ${CINDER_CONF} ${be_name} driver_use_ssl "True"
    iniset ${CINDER_CONF} ${be_name} cinder_emc_config_file \
    "$CINDER_CONF_DIR/cinder_emc_config_$be_name.xml"

    touch ${CINDER_CONF_DIR}/cinder_emc_config_${be_name}.xml
    echo "<?xml version='1.0' encoding='UTF-8'?>" > \
    ${CINDER_CONF_DIR}/cinder_emc_config_${be_name}.xml
    echo "<EMC>" >> ${CINDER_CONF_DIR}/cinder_emc_config_${be_name}.xml

    configure_single_pool ${be_name}

    echo "</EMC>" >> ${CINDER_CONF_DIR}/cinder_emc_config_${be_name}.xml
    if [ ! -f "$CINDER_CONF_DIR/cinder_emc_config.xml" ]; then
        ln -s ${CINDER_CONF_DIR}/cinder_emc_config_${be_name}.xml \
            ${CINDER_CONF_DIR}/cinder_emc_config.xml
    fi
}

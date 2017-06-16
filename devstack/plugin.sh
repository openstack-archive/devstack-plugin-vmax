#!/bin/bash

# devstack/plugin.sh
# Setup VMAX as backend for Devstack

function configure_port_groups {
    local be_name=$1
    echo "<PortGroups>" >> \
        ${CINDER_CONF_DIR}/cinder_dell_emc_config_$be_name.xml
    dell_emc_temp="${be_name}_PortGroup"
    dell_emc_portGroups=0
    for i in ${!VMAX*}; do
        temp1=${i##${dell_emc_temp}}
        if [[ "$temp1" == "$i" ]]; then
            continue
        fi
        arrIN=(${temp1//_/ })
        if [[ "${arrIN[0]}" -gt "$dell_emc_portGroups" ]]; then
            dell_emc_portGroups=${arrIN[0]}
        fi
    done
    for (( m=1 ; m<=dell_emc_portGroups ; m++ )) ; do
        dell_emc_temp="${be_name}_PortGroup${m}"
        echo "<PortGroup>${!dell_emc_temp}</PortGroup>" >> \
        ${CINDER_CONF_DIR}/cinder_dell_emc_config_${be_name}.xml
    done
    echo "</PortGroups>" >> \
        ${CINDER_CONF_DIR}/cinder_dell_emc_config_${be_name}.xml
}

function configure_single_pool {
    local be_name=$1
    for val in "RestServerIp" "RestServerPort" "RestUserName" "RestPassword"\
    "Array" "SRP" "SSLVerify" ; do
        dell_emc_temp="${be_name}_${val}"
        if [  -n "${!dell_emc_temp}" ]; then
            echo "<${val}>${!dell_emc_temp}</${val}>" >> \
            ${CINDER_CONF_DIR}/cinder_dell_emc_config_${be_name}.xml
        fi
    done
    configure_port_groups ${be_name}
}

function configure_cinder_backend_dell_emc {
    local be_name=$1
    local emc_multi=${be_name%%_*}
    iniset ${CINDER_CONF} ${be_name} volume_backend_name ${be_name}
    storage_proto="${be_name}_StorageProtocol"
    vmax_directory="cinder.volume.drivers.dell_emc.vmax."
    if [[ "${!storage_proto}" == "iSCSI" ]];
    then
        iniset ${CINDER_CONF} ${be_name} volume_driver \
        "${vmax_directory}iscsi.VMAXISCSIDriver"
    fi
    if [ "${!storage_proto}" = "FC" ]
    then
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
    ${CINDER_CONF_DIR}/cinder_dell_emc_config_${be_name}.xml
    if [ ! -f "$CINDER_CONF_DIR/cinder_emc_config.xml" ]; then
       ln -s ${CINDER_CONF_DIR}/cinder_dell_emc_config_${be_name}.xml \
       ${CINDER_CONF_DIR}/cinder_emc_config.xml
    fi
}

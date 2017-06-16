# perforceupdate.sh - Devstack extras script

function create_volume_types {
    # Create volume types
    if is_service_enabled c-api && [[ -n "$CINDER_ENABLED_BACKENDS" ]]; then
        local be be_name
        for be in ${CINDER_ENABLED_BACKENDS//,/ }; do
            be_name=${be##*:}
            be_type=${be%%:*}
            emctemp="EMC_${be_name}_TYPE"
            no_of_volume_types=0
            for i in ${!EMC_VMAX*}; do
                temp1=${i##$emctemp}
                if [[ "$temp1" == "$i" ]]; then
                    continue
                fi
                arrIN=(${temp1//_/ })
                if [[ "${arrIN[0]}" -gt "$no_of_volume_types" ]]; then
                    no_of_volume_types=${arrIN[0]}
                fi
            done
            for (( m=1 ; m<=no_of_volume_types ; m++ )) ; do
                type_name="EMC_${be_name}_TYPE${m}_NAME"
                openstack --os-region-name="$REGION_NAME" volume type\
                create --property volume_backend_name="${be_name}"\
                ${!type_name}
                array_temp="EMC_${be_name}_Array"
                srp_temp="EMC_${be_name}_SRP"
                slo_temp="None"
                workload_temp="None"
                pool_name=${!srp_temp}+${!array_temp}
                emctemp="EMC_${be_name}_TYPE${m}_WORKLOAD"
                if [  -n "${!emctemp}" ]; then
                    workload_temp="EMC_${be_name}_TYPE${m}_WORKLOAD"
                    pool_name=${!workload_temp}+$pool_name
                else
                    pool_name=${workload_temp}+$pool_name
                fi
                emctemp="EMC_${be_name}_TYPE${m}_SLO"
                if [  -n "${!emctemp}" ]; then
                    slo_temp="EMC_${be_name}_TYPE${m}_SLO"
                    pool_name=${!slo_temp}+$pool_name
                else
                    pool_name=${slo_temp}+$pool_name
                fi
                cinder type-key ${!type_name} set pool_name="${pool_name}"

            done
        done
    fi
}

function update_source_code {
if [ -d $DEST/vmax_files ]; then
    #mkdir -p $CINDER_DIR/cinder/volume/drivers/dell_emc/vmax/rest
    #rm -rf $CINDER_DIR/cinder/volume/drivers/dell_emc/vmax/rest/*.py
    cp $DEST/vmax_files/*.py $CINDER_DIR/cinder/volume/drivers/dell_emc/vmax/
fi
}

function temp_update_opts {
    dell_prefix='cinder_volume_drivers_dell_emc'
    rest_suffix='_vmax_rest_common'
    sp='                '
    from="from cinder.volume.drivers.dell_emc.vmax.rest import common as ${dell_prefix}${rest_suffix}"
    grep -q  ${dell_prefix}${rest_suffix} $CINDER_DIR/cinder/opts.py || \
    sed -E -i \
    "s/(${dell_prefix})(_vmax_common.emc_opts,)/\1\2\n${sp}\1${rest_suffix}.vmax_opts,/" \
    $CINDER_DIR/cinder/opts.py && sed -E -i \
    "0,/${dell_prefix}_vmax_common/s//${dell_prefix}_vmax_common\n${from}/" \
    $CINDER_DIR/cinder/opts.py
}

function configure_single_pool {
    local be_name=$1
    for val in "RestServerIp" "RestServerPort" "RestUserName" "RestPassword"\
    "Array" "SRP" "SSLVerify" ; do
        emctemp="EMC_${be_name}_${val}"
        if [  -n "${!emctemp}" ]; then
            echo "<${val}>${!emctemp}</${val}>" >> \
            $CINDER_CONF_DIR/cinder_dell_emc_config_$be_name.xml
        fi
    done
    emctemp="EMC_${be_name}_PortGroup1"
    echo "<PortGroups>" >> $CINDER_CONF_DIR/cinder_dell_emc_config_$be_name.xml
    emctemp="EMC_${be_name}_PortGroup"
    ecomServerPortGroups=0
    for i in ${!EMC_VMAX*}; do
        temp1=${i##$emctemp}
        if [[ "$temp1" == "$i" ]]; then
            continue
        fi
        arrIN=(${temp1//_/ })
        if [[ "${arrIN[0]}" -gt "$ecomServerPortGroups" ]]; then
            ecomServerPortGroups=${arrIN[0]}
        fi
    done
    for (( m=1 ; m<=ecomServerPortGroups ; m++ )) ; do
        emctemp="EMC_${be_name}_PortGroup${m}"
        echo "<PortGroup>${!emctemp}</PortGroup>" >> \
        $CINDER_CONF_DIR/cinder_dell_emc_config_$be_name.xml
    done
    echo "</PortGroups>" >> $CINDER_CONF_DIR/cinder_dell_emc_config_$be_name.xml
}

function configure_cinder_backend_emc {
    local be_name=$1
    local emc_multi=${be_name%%_*}
    iniset $CINDER_CONF $be_name volume_backend_name $be_name
    emctemp="EMC_${be_name}_StorageProtocol"
    if [[ "${!emctemp}" == "iSCSI" ]];
    then
        iniset $CINDER_CONF $be_name volume_driver \
        "cinder.volume.drivers.dell_emc.vmax.iscsi.VMAXISCSIDriver"
    fi
    if [ "${!emctemp}" = "FC" ]
    then
        iniset $CINDER_CONF $be_name volume_driver \
        "cinder.volume.drivers.dell_emc.vmax.fc.VMAXFCDriver"
    fi

    iniset $CINDER_CONF $be_name cinder_dell_emc_config_file \
    "$CINDER_CONF_DIR/cinder_dell_emc_config_$be_name.xml"

    touch $CINDER_CONF_DIR/cinder_dell_emc_config_$be_name.xml
    echo "<?xml version='1.0' encoding='UTF-8'?>" > \
    $CINDER_CONF_DIR/cinder_dell_emc_config_$be_name.xml
    echo "<EMC>" >> $CINDER_CONF_DIR/cinder_dell_emc_config_$be_name.xml

    configure_single_pool ${be_name}

    echo "</EMC>" >> $CINDER_CONF_DIR/cinder_dell_emc_config_$be_name.xml
    xmllint --format --output $CINDER_CONF_DIR/cinder_dell_emc_config_$be_name.xml \
    $CINDER_CONF_DIR/cinder_dell_emc_config_$be_name.xml
    if [ ! -f "$CINDER_CONF_DIR/cinder_emc_config.xml" ]; then
       ln -s $CINDER_CONF_DIR/cinder_dell_emc_config_$be_name.xml \
       $CINDER_CONF_DIR/cinder_emc_config.xml
    fi
}

function enable_virtual_environment {
    ## We need to enable virtual environment to use global packages if it
    ## exists
    if [[ ${USE_VENV} = True ]]; then
        virtualenv --system-site-packages /opt/stack/cinder.venv
    fi
}

function install_vmax_prerequisites {

    if is_ubuntu; then
        sudo apt-get install -y libxml2-utils
    fi
}

if is_service_enabled vmax_plugin; then
    if [[ "$1" == "stack" && "$2" == "pre-install" ]]; then
        # Install prerequisites i.e. pywbem, xmllint
        install_vmax_prerequisites
    elif [[ "$1" == "stack" && "$2" == "install" ]]; then
        enable_virtual_environment
    elif [[ "$1" == "stack" && "$2" == "post-config" ]]; then
        # Update config files with source code from git
        #update_dell_emc_directory
        update_source_code
        #temp_update_opts

    elif [[ "$1" == "stack" && "$2" == "extra" ]]; then
        # no-op
        :
        #update_volume_type
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
fi

#!/usr/bin/bash
#!/usr/bin/zsh

# Set Variable
export PRIN="printf"
export ECMD="echo -e"
export CR='\e[0m'
export COL_LIGHT_GREEN='\e[1;32m'
export COL_LIGHT_RED='\e[1;31m'
export TICK="[${COL_LIGHT_GREEN}✓${CR}]"
export CROSS="[${COL_LIGHT_RED}✗${CR}]"
export INFO="[i]"
export QST="[?]"
export DONE="${COL_LIGHT_GREEN} done !${CR}"
export SLP="sleep 0.69s"
export OPENWRT_ORIGINAL_URL="https://downloads.openwrt.org/releases"
export OPENWRT_RASPI="bcm27xx"
# V2ray Version
export V2RAY_VERSION="4.41.1-1"

error() {
    ${PRIN} "$1 ${CROSS}"
    exit
}

# Select OpenWrt version from official repository
OPENWRT_VERSION () {
    ${ECMD}
    PS3=" ${QST} Select version : "
    opts1=("21.02.0")
        select opt in "${opts1[@]}"
        do
            case $opt in
                "21.02.0")
                    export OPENWRT_VERZION="21.02.0"
                    break
                    ;;
                *)
                    ${ECMD} "invalid option $REPLY"
                    ;;
            esac
        done
}

# Select Raspberry Pi Model
OPENWRT_MODEL () {
export MODEL_1="Raspberry Pi 1 (32 bit) compatible on pi 0,0w,1B,1B+"
export MODEL_2="Raspberry Pi 2 (32 bit) compatible on pi 2B,2B+,3B,3B+,CM3,4B,CM4"
export MODEL_3="Raspberry Pi 3 (64 bit) compatible on pi 2Brev2,3B,3B+,CM3"
export MODEL_4="Raspberry Pi 4 (64 bit) compatible on pi 4B,CM4"
        ${ECMD} "   ───────────────────────────────────────────────────────────────────────────────"
        ${ECMD} "   │  Model  │                           Descriptions                            │"
        ${ECMD} "   ───────────────────────────────────────────────────────────────────────────────"
        ${ECMD} "   │ bcm2708 │ ${MODEL_1}              │"
        ${ECMD} "   │ bcm2709 │ ${MODEL_2} │"
        ${ECMD} "   │ bcm2710 │ ${MODEL_3}        │"
        ${ECMD} "   │ bcm2711 │ ${MODEL_4}                   │"
        ${ECMD} "   ───────────────────────────────────────────────────────────────────────────────"
        ${ECMD}
            PS3=" ${QST} Select Raspberry Pi model : "
            opts2=("bcm2708" "bcm2709" "bcm2710" "bcm2711")
                select opt in "${opts2[@]}"
                do
                    case $opt in
                        "bcm2708")
                            export MODEL_ARCH="bcm2708"
                            export INFO_MODEL="rpi"
                            export ARCH="arm_arm1176jzf-s_vfp"
                            export AKA_ARCH="arm32-v6"
                            export SHORT_ARCH="arm"
                            export MODELL="${MODEL_1}"
                            break
                            ;;
                        "bcm2709")
                            export MODEL_ARCH="bcm2709"
                            export INFO_MODEL="rpi-2"
                            export ARCH="arm_cortex-a7_neon-vfpv4"
                            export AKA_ARCH="arm32-v7a"
                            export SHORT_ARCH="arm"
                            export MODELL="${MODEL_2}"
                            break
                            ;;
                        "bcm2710")
                            export MODEL_ARCH="bcm2710"
                            export INFO_MODEL="rpi-3"
                            export ARCH="aarch64_cortex-a53"
                            export AKA_ARCH="arm64-v8a"
                            export SHORT_ARCH="arm64"
                            export MODELL="${MODEL_3}"
                            break
                            ;;
                        "bcm2711")
                            export MODEL_ARCH="bcm2711"
                            export INFO_MODEL="rpi-4"
                            export ARCH="aarch64_cortex-a72"
                            export AKA_ARCH="arm64-v8a"
                            export SHORT_ARCH="arm"
                            export MODELL="${MODEL_4}"
                            break
                            ;;
                        *)
                            ${ECMD} "invalid option $REPLY"
                            ;;
                    esac
                done
}

OPENWRT_CUSTOM () {
    # Set partition size of kernel
    read -r -p " ${QST} Write size of /boot [>30 Mb] : " BOOTFS
    # Set partition size of /rootfs
    read -r -p " ${QST} Write size of /root [>300 Mb] : " ROOTFS
    # Set ip address
    read -r -p " ${QST} Write ip address you want to use [192.168.1.1] : " IP_ADDR
}

ZEROWRT_TYPE () {
    ${SLP}
    PS3=" ${QST} Select ZEROWRT type : "
    opts1=("tiny" "gimmick")
        select opt in "${opts1[@]}"
        do
            case $opt in
                "tiny")
                    export Ztype="tiny"
                    export DIR_PACKAGES="tiny/packages.txt"
                    export DIR_DISABLED="tiny/disabled.txt"
                    export DIR_TYPE="tiny/"
                    break
                    ;;
                "gimmick")
                    export Ztype="gimmick"
                    export DIR_PACKAGES="gimmick/packages.txt"
                    export DIR_DISABLED="gimmick/disabled.txt"
                    export DIR_TYPE="gimmick/"
                    break
                    ;;
                *)
                    ${ECMD} "invalid option $REPLY"
                    ;;
            esac
        done
}

# Preparation before cooking ZeroWrt
OPENWRT_PREPARE () {
export IMAGEBUILDER_DIR="openwrt-imagebuilder-${OPENWRT_VERZION}-${OPENWRT_RASPI}-${MODEL_ARCH}.Linux-x86_64"
export IMAGEBUILDER_FILE="${IMAGEBUILDER_DIR}.tar.xz"
export IMAGEBUILDER_URL="${OPENWRT_ORIGINAL_URL}/${OPENWRT_VERZION}/targets/${OPENWRT_RASPI}/${MODEL_ARCH}/${IMAGEBUILDER_FILE}"
export ROOT_DIR="${IMAGEBUILDER_DIR}/files"
export HOME_DIR="${ROOT_DIR}/root"
    # Prepare imagebuilder
    ${PRIN} " %b %s ... " "${INFO}" "Downloading Imagebuilder"
    	wget -q ${IMAGEBUILDER_URL} || error "Failed to download imagebuilder !"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s ... " "${INFO}" "Extracting Imagebuilder"
        tar xf ${IMAGEBUILDER_FILE} || error "Failed to extract file !"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s ... " "${INFO}" "Removing Imagebuilder"
        rm ${IMAGEBUILDER_FILE} || error "Failed to remove file !"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s ... " "${INFO}" "Preparing requirements"
        #cp $(pwd)/${DIR_TYPE}/disabled.txt ${IMAGEBUILDER_DIR} || error "Failed to copy file:disabled.txt !"
        #cp $(pwd)/${DIR_TYPE}/packages.txt ${IMAGEBUILDER_DIR} || error "Failed to copy file:packages.txt !"
        export ZEROWRT_DISABLED="$(echo $(cat $(pwd)/${DIR_TYPE}/disabled.txt))"
        export ZEROWRT_PACKAGES="$(echo $(cat $(pwd)/${DIR_TYPE}/packages.txt))"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    # Prepare data
    ${PRIN} " %b %s ... " "${INFO}" "Preparing data"
        mkdir -p ${ROOT_DIR} || error "Failed to create files/root directory !"
        cp -arf $(pwd)/${DIR_TYPE}/data/* ${ROOT_DIR} || error "Failed to copy data !"
        chmod +x ${ROOT_DIR}/usr/bin/neofetch || error "Failed to chmod:neofetch"
        chmod +x ${ROOT_DIR}/etc/zshinit || error "Failed to chmod:zshinit"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    # Change main directory
    cd ${IMAGEBUILDER_DIR} || error "Failed to change directory !"
    ${PRIN} " %b %s " "${INFO}" "Current directory : $(pwd)"
    ${SLP}
    ${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s ... " "${INFO}" "Configure data"
        sed -i -e "s/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=${BOOTFS}/" .config || error "Failed to change bootfs size !"
        sed -i -e "s/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=${ROOTFS}/" .config || error "Failed to change rootfs size !"
        sed -i 's/4.3.2.1/${IP_ADDR}/g' files/etc/config/network || error "Failed to change openwrt ip address"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s ... " "${INFO}" "Installing ohmyzsh"
        export OMZ_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
        git clone -q ${OMZ_REPO} files/root/.oh-my-zsh || error "Failed to clone ${OMZ_REPO}"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s ... " "${INFO}" "Installing mikhmon"
        export MIKHMON_REPO="https://github.com/laksa19/mikhmonv3.git"
        mkdir -p files/etc/init.d || error "Failed to create dir:init.d"
        git clone -q ${MIKHMON_REPO} files/www/mikhmon || error "Failed to clone ${MIKHMON_REPO}"
        sed -i 's/str_replace(" ","_",date("Y-m-d H:i:s"))/str_replace(date)/g' files/www/mikhmon/index.php || error "Failed to mod:mikhmon/index.php"
        sed -i 's/strtolower(date("M"))/strtolower(date)/g' files/www/mikhmon/include/menu.php || error "Failed to mod:mikhmon/menu.php"
        sed -i 's/strtolowerdate("Y"))/strtolower(date)/g' files/www/mikhmon/include/menu.php || error "Failed to mod:mikhmon/menu.php"
        cat > files/etc/init.d/mikhmon << EOF
#!/bin/sh /etc/rc.common
# Mikhmon init script beta (C) 2021 ZeroWRT
# Copyright (C) 2007 OpenWrt.org

START=69
STOP=01
USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_param command php-cli -S 0.0.0.0:4433 -t /www/mikhmon
	echo "Mikhmon Started"
    procd_close_instance
}

stop_service() {
	kill $(ps | grep 'php-cli -S 0.0.0.0:4433 -t /www/mikhmon' | awk '{print $1}' | awk 'FNR <= 1')
	echo "Mikhmon Stopped"
}

reload_service() {
	if pgrep "php-cli" ; then
	 stop
	 start
	else
	 start	
	fi
}
EOF
    chmod +x files/etc/init.d/mikhmon || error "Failed to chmod file:mikhmon.init"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
}

LIBERNET_PREPARE () {
        # Install libernet
        ${PRIN} " %b %s ... \n" "${INFO}" "Installing libernet"
        export LIBERNET_REPO="https://github.com/lutfailham96/libernet.git"
        mkdir -p files/www/libernet || error "Failed to create libernet dir"
        git clone -q ${LIBERNET_REPO} || error "Failed to clone repo:${LIBERNET_REPO}"
        cp -arf libernet/web/* files/www/libernet || error "Failed to install libernet"
        mkdir -p files/usr/bin
            wget -q https://github.com/lutfailham96/libernet/raw/main/binaries.txt || error "Failed to download file:binaries.txt !"
                while IFS= read -r line; do
                    if ! which ${line} > /dev/null 2>&1 ; then
                    bin="files/usr/bin/${line}"
                    ${ECMD} "\e[0;34mInstalling\e[0m ${line} ..."
                    wget -q -O "${bin}" "https://github.com/lutfailham96/libernet-proprietary/raw/main/${ARCH}/binaries/${line}" || error "Failed to download binaries !"
                    chmod +x "${bin}" || error "Failed to chmod !"
                    fi
                done < binaries.txt
        # Install v2ray-core for libernet
            mkdir -p packages
            export V2RAY_REPO=$(curl -sL https://github.com/kuoruan/openwrt-v2ray/releases/latest | grep '/kuoruan/openwrt-v2ray/releases/download' | sed -e 's/\"//g' -e 's/ //g' -e 's/rel=.*//g' -e 's#<ahref=#http://github.com#g' | grep 'v2ray-core_' | grep ${ARCH})
            wget -q -P packages/ ${V2RAY_REPO} || error "Failed to download file:v2ray.ipk !"
            ${ECMD} "src v2ray-core file:packages" >> repositories.conf
        ${PRIN} " %b %s " "${INFO}" "Install Libernet"
        ${PRIN} "%b" "${DONE}"
        ${SLP}
        ${PRIN} " %b\\n" "${TICK}"
}

OPENCLASH_PREPARE () {
        # Install openclash
        ${PRIN} " %b %s ... " "${INFO}" "Installing OpenClash"
            export OC_REPO=$(curl -sL https://github.com/vernesong/OpenClash/releases | grep 'luci-app-openclash_' | sed -e 's/\"//g' -e 's/ //g' -e 's/rel=.*//g' -e 's#<ahref=#http://github.com#g' | awk 'FNR <= 1')
            wget -q -P packages/ ${OC_REPO} || error "Failed to download file:luci-app-openclash.ipk !"
            ${ECMD} "src luci-app-openclash file:packages" >> repositories.conf
        ${SLP}
	    ${PRIN} "%b\\n" "${TICK}"
}

V2RAYA_PREPARE () {
        # Install v2ray
        ${PRIN} " %b %s ... \n" "${INFO}" "Installing v2rayA"
            export V2FLY_REPO=$(curl -sL https://github.com/v2fly/v2ray-core/releases/latest | grep 'v2ray-linux'| sed -e 's/\"//g' -e 's/ //g' -e 's/rel=.*//g' -e 's#<ahref=#http://github.com#g' | grep ${AKA_ARCH} | grep -v '.dgst' | awk 'FNR <= 1')
            export DIR_V2RAYA="files/etc/v2raya"
            wget -q ${V2FLY_REPO} || error "Failed to download file:v2ray-linux from v2fly"
            mkdir -p ${DIR_V2RAYA}/bin || error "Failed to create directoy:${DIR_V2RAYA}/bin"
            unzip -d ${DIR_V2RAYA} v2ray-linux-${AKA_ARCH}.zip || error "Failed to decompressed file:v2ray.zip"
            cp ${DIR_V2RAYA}/v2ray ${DIR_V2RAYA}/bin || error "Failed to install v2ray"
            cp ${DIR_V2RAYA}/v2ctl ${DIR_V2RAYA}/bin || error "Failed to install v2ctl"
            chmod +x ${DIR_V2RAYA}/bin/v2ray || error "Failed to chmod file:v2ray"
            chmod +x ${DIR_V2RAYA}/bin/v2ctl || error "Failed to chmod file:v2ctl"
        # Install geodata and set v2rayA
            export V2RAYA_REPO=$(curl -sL https://github.com/v2rayA/v2rayA/releases/latest | grep 'v2raya_linux'| sed -e 's/\"//g' -e 's/ //g' -e 's/rel=.*//g' -e 's#<ahref=#http://github.com#g' | grep ${SHORT_ARCH}_ | awk 'FNR <= 1')
            export GEO_REPO="https://github.com/v2rayA/dist-v2ray-rules-dat/blob/master"
            export WDIR_V2RAYA="files/usr/bin/v2raya"
            wget -q -O ${WDIR_V2RAYA} ${V2RAYA_REPO} || error "Failed to download file:v2rayA"
            chmod +x ${WDIR_V2RAYA} || error "Failed to chmod file:v2raya"
            mkdir -p files/usr/share/v2ray || error "Failed to create dir:files/usr/share/v2ray"
            for p in geoip.dat geosite.dat ; do
                wget -q -O files/usr/share/v2ray/${p} ${GEO_REPO}/${p} || error "Failed to download file:geodata"
            done
            chmod +x files/etc/init.d/v2raya || error "Failed to chmod file:init v2raya"
        ${PRIN} " %b %s " "${INFO}" "Install v2rayA"
        ${PRIN} "%b" "${DONE}"
        ${SLP}
        ${PRIN} " %b\\n" "${TICK}"
}

ADDITIONAL_PREPARE () {
        # Install luci theme edge
            export EDGE_REPO=$(curl -sL https://github.com/kiddin9/luci-theme-edge/releases | grep 'luci-theme-edge_' | sed -e 's/\"//g' -e 's/ //g' -e 's/rel=.*//g' -e 's#<ahref=#http://github.com#g' | awk 'FNR <= 1')
            wget -q -P packages/ ${EDGE_REPO} || error "Failed to download file:luci-theme-edge.ipk !"
            ${ECMD} "src luci-theme-edge file:packages" >> repositories.conf
}

# Cook the image
OPENWRT_BUILD () {
    # Build
    ${PRIN} " %b %s ... \n" "${INFO}" "Ready to cook"
        sleep 2
        make image PROFILE="${INFO_MODEL}" \
        FILES="$(pwd)/files/" \
        EXTRA_IMAGE_NAME="zerowrt-${Ztype}" \
        PACKAGES="${ZEROWRT_PACKAGES}" \
        DISABLED_SERVICES="${ZEROWRT_DISABLED}" || error "Failed to build image !"
    ${PRIN} " %b %s " "${INFO}" "Cleanup"
    # Back to first directory
    cd .. || error "Can't back to working directory !"
    # Store the firmware to ez dir
    mkdir -p results || error "Failed to create directory"
    cp -r ${IMAGEBUILDER_DIR}/bin/targets/${OPENWRT_RASPI}/${MODEL_ARCH} results || error "Failed to store firmware !"
    # Clean up
    rm -rf ${IMAGEBUILDER_DIR} || error "Failed to remove imagebuilder directory !"
    ${SLP}
	${PRIN} " %b\\n" "${TICK}"
    ${PRIN} " %b %s " "${INFO}" "Build completed for ${INFO_MODEL}"
    ${SLP}
	${PRIN} " %b\\n" "${TICK}"
    ${PRIN} " %b %s " "${INFO}" "Image stored at : $(pwd)/results/${MODEL_ARCH}"
    ${SLP}
	${PRIN} " %b\\n" "${TICK}"
}

main () {
    clear ; OPENWRT_VERSION
    clear ; OPENWRT_MODEL
    clear ; OPENWRT_CUSTOM
    clear ; ZEROWRT_TYPE
    clear ; OPENWRT_PREPARE
    # Print info version
        ${PRIN} " %b %s " "${INFO}" "Selected Version : ${OPENWRT_VERZION}"
        ${SLP}
        ${PRIN} "%b\\n" "${TICK}"
    # Print info model
        ${PRIN} " %b %s " "${INFO}" "Selected model: ${INFO_MODEL}"
        ${SLP}
        ${PRIN} "%b\\n" "${TICK}"
    # Print info size bootfs
        ${PRIN} " %b %s " "${INFO}" "CONFIG_TARGET_KERNEL_PARTSIZE=${BOOTFS}"
        ${SLP}
        ${PRIN} "%b\\n" "${TICK}"
    # Print info size rootfs
        ${PRIN} " %b %s " "${INFO}" "CONFIG_TARGET_ROOTFS_PARTSIZE=${ROOTFS}"
        ${SLP}
        ${PRIN} "%b\\n" "${TICK}"
    # Print info type zerowrt
        ${PRIN} " %b %s " "${INFO}" "Selected Type : ${Ztype}"
        ${SLP}
        ${PRIN} "%b\\n" "${TICK}"
    if [[ "${Ztype}" == "tiny" ]] ; then
        OPENWRT_BUILD
    elif [[ "${Ztype}" == "gimmick" ]] ; then
        LIBERNET_PREPARE
        OPENCLASH_PREPARE
        V2RAYA_PREPARE
        ADDITIONAL_PREPARE
        OPENWRT_BUILD
    fi
}

main
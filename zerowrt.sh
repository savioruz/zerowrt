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
export R=20
export C=70
export OPENWRT_ORIGINAL_URL="https://downloads.openwrt.org/releases"
# export OPENWRT_RASPI="bcm27xx"
# export OPENWRT_RASPI_OLD="brcm2708"
# V2ray Version
export V2RAY_VERSION="4.41.1-1"

error() {
    ${PRIN} "$1 ! ${CROSS}"
    exit
}

# Select OpenWrt version from official repository
OPENWRT_VERSION () {
    DIALOG_VERSION=$(whiptail --title "Openwrt Version" \
		--radiolist "Choose your version" ${R} ${C} 3 \
		"21.02.0" "Latest Stable Release" ON \
		"19.07.8" "Old Stable Release" OFF \
		"18.06.9" "Old Stable Archive"  OFF \
    3>&1 1>&2 2>&3)

    if [ $? = 0 ] ; then
        export OPENWRT_VERZION=${DIALOG_VERSION}
    else
        error "Operation Canceled"
    fi

	if [[ ${DIALOG_VERSION} = 19.* ]] ; then
		export OPENWRT_RASPI="brcm2708"
	elif [[ ${DIALOG_VERSION} = 18.* ]] ; then
		export OPENWRT_RASPI="brcm2708"
	elif [[ ${DIALOG_VERSION} = 21.* ]] ; then
		export OPENWRT_RASPI="bcm27xx"
	fi
}


# Select Raspberry Pi Model
OPENWRT_MODEL () {
	export MODEL_1="Pi 1 (32 bit) compatible on pi 0,0w,1B,1B+"
	export MODEL_2="Pi 2 (32 bit) compatible on pi 2B,2B+,3B,3B+,CM3"
	export MODEL_3="Pi 3 (64 bit) compatible on pi 2Brev2,3B,3B+,CM3"
	export MODEL_4="Pi 4 (64 bit) compatible on pi 4B,CM4"

    DIALOG_MODEL=$(whiptail --title "Raspberry Pi Model" \
		--radiolist "Choose your raspi model" ${R} ${C} 4 \
		"bcm2708" "${MODEL_1}" OFF \
		"bcm2709" "${MODEL_2}"  OFF \
		"bcm2710" "${MODEL_3}"  OFF \
		"bcm2711" "${MODEL_4}"  OFF \
		3>&1 1>&2 2>&3)

    if [ $? = 0 ] ; then
        export MODEL_ARCH=${DIALOG_MODEL}
    else
        error "Operation Canceled"
    fi

    if [[ ${DIALOG_MODEL} = bcm2708 ]] ; then
        export INFO_MODEL="rpi"
        export ARCH="arm_arm1176jzf-s_vfp"
        export AKA_ARCH="arm32-v6"
        export SHORT_ARCH="arm"
        export MODELL="${MODEL_1}"
    elif [[ ${DIALOG_MODEL} = bcm2709 ]] ; then
		export INFO_MODEL="rpi-2"
        export ARCH="arm_cortex-a7_neon-vfpv4"
        export AKA_ARCH="arm32-v7a"
        export SHORT_ARCH="arm"
        export MODELL="${MODEL_2}"
	elif [[ ${DIALOG_MODEL} = bcm2710 ]] ; then
		export INFO_MODEL="rpi-3"
		export ARCH="aarch64_cortex-a53"
        export AKA_ARCH="arm64-v8a"
        export SHORT_ARCH="arm64"
        export MODELL="${MODEL_3}"
	elif [[ ${DIALOG_MODEL} = bcm2711 ]] ; then
		export INFO_MODEL="rpi-4"
		export ARCH="aarch64_cortex-a72"
        export AKA_ARCH="arm64-v8a"
        export SHORT_ARCH="arm"
        export MODELL="${MODEL_4}"
	fi
}

OPENWRT_BOOTFS () {
	DIALOG_BOOT=$(whiptail --title "Set partition size of /boot" \
        --inputbox "Write size of /boot [>30 Mb] :" ${R} ${C} "30" \
        3>&1 1>&2 2>&3)

    if [ $? = 0 ] ; then
        # echo "Size of /boot partition : ${DIALOG_BOOT} Mb"
		export BOOTFS=${DIALOG_BOOT}
    else
        error "Operation Canceled"
    fi
}

OPENWRT_ROOTFS () {
	DIALOG_ROOT=$(whiptail --title "Set partition size of /root" \
        --inputbox "Write size of /root [>300 Mb] :" ${R} ${C} "300" \
        3>&1 1>&2 2>&3)

    if [ $? = 0 ] ; then
		export ROOTFS=${DIALOG_ROOT}
    else
        error "Operation Canceled"
    fi
}

OPENWRT_IPADDR () {
	DIALOG_IPADDR=$(whiptail --title "Set default ip address" \
        --inputbox "Write ip address openwrt :" ${R} ${C} "192.168.1.1" \
        3>&1 1>&2 2>&3)

    if [ $? = 0 ] ; then
		export IP_ADDR=${DIALOG_IPADDR}
    else
        error "Operation Canceled"
    fi
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
        export DIR_TYPE="tiny/"
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
        sed -i -e "s/4.3.2.1/${IP_ADDR}/" files/etc/config/network || error "Failed to change openwrt ip address"
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
        #sed -i 's/str_replace(" ","_",date("Y-m-d H:i:s"))/str_replace(date)/g' files/www/mikhmon/index.php || error "Failed to mod:mikhmon/index.php"
        #sed -i 's/strtolower(date("M"))/strtolower(date)/g' files/www/mikhmon/include/menu.php || error "Failed to mod:mikhmon/menu.php"
        #sed -i 's/strtolowerdate("Y"))/strtolower(date)/g' files/www/mikhmon/include/menu.php || error "Failed to mod:mikhmon/menu.php"
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

OPENCLASH_PREPARE () {
        # Install openclash
        ${PRIN} " %b %s ... " "${INFO}" "Installing OpenClash"
            export OC_REPO=$(curl -sL https://github.com/vernesong/OpenClash/releases | grep 'luci-app-openclash_' | sed -e 's/\"//g' -e 's/ //g' -e 's/rel=.*//g' -e 's#<ahref=#http://github.com#g' | awk 'FNR <= 1')
            wget -q -P packages/ ${OC_REPO} || error "Failed to download file:luci-app-openclash.ipk !"
            ${ECMD} "src luci-app-openclash file:packages" >> repositories.conf
        ${SLP}
	    ${PRIN} "%b\\n" "${TICK}"
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
    OPENWRT_VERSION
    OPENWRT_MODEL
    OPENWRT_BOOTFS
	OPENWRT_ROOTFS
	OPENWRT_IPADDR
    OPENWRT_PREPARE
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
    OPENCLASH_PREPARE
    ADDITIONAL_PREPARE
    OPENWRT_BUILD
}

main
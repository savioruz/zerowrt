#!/usr/bin/bash
#!/usr/bin/zsh

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
                            export MODELL="${MODEL_1}"
                            break
                            ;;
                        "bcm2709")
                            export MODEL_ARCH="bcm2709"
                            export INFO_MODEL="rpi-2"
                            export ARCH="arm_cortex-a7_neon-vfpv4"
                            export MODELL="${MODEL_2}"
                            break
                            ;;
                        "bcm2710")
                            export MODEL_ARCH="bcm2710"
                            export INFO_MODEL="rpi-3"
                            export ARCH="aarch64_cortex-a53"
                            export MODELL="${MODEL_3}"
                            break
                            ;;
                        "bcm2711")
                            export MODEL_ARCH="bcm2711"
                            export INFO_MODEL="rpi-4"
                            export ARCH="aarch64_cortex-a53"
                            export MODELL="${MODEL_4}"
                            break
                            ;;
                        *)
                            ${ECMD} "invalid option $REPLY"
                            ;;
                    esac
                done
}

OPENWRT_SIZE () {
    # Set partition size of kernel
    read -r -p " ${QST} Write size of /boot [>30 Mb] : " BOOTFS
    # Set partition size of /rootfs
    read -r -p " ${QST} Write size of /root [>200 Mb] : " ROOTFS
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
        cp $(pwd)/${DIR_TYPE}/disabled.txt ${IMAGEBUILDER_DIR} || error "Failed to copy file:disabled.txt !"
        cp $(pwd)/${DIR_TYPE}/packages.txt ${IMAGEBUILDER_DIR} || error "Failed to copy file:packages.txt !"
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
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s ... " "${INFO}" "Installing ohmyzsh"
        export OMZ_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
        git clone -q ${OMZ_REPO} files/root/.oh-my-zsh || error "Failed to clone ${OMZ_REPO}"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
}

LIBERNET_PREPARE () {
    # Install libernet proprietary
    ${PRIN} " %b %s ... \n" "${INFO}" "Installing libernet"
        wget -q https://github.com/lutfailham96/libernet/raw/main/binaries.txt || error "Failed to download file:binaries.txt !"
            while IFS= read -r line; do
                if ! which ${line} > /dev/null 2>&1 ; then
                bin="files/usr/bin/${line}"
                mkdir -p files/usr/bin
                ${ECMD} "\e[0;34mInstalling\e[0m ${line} ..."
                wget -q -O "${bin}" "https://github.com/lutfailham96/libernet-proprietary/raw/main/${ARCH}/binaries/${line}" || error "Failed to download binaries !"
                chmod +x "${bin}" || error "Failed to chmod !"
                fi
            done < binaries.txt
        ${PRIN} " %b %s " "${INFO}" "Configure local repositories"
        # Install v2ray
        mkdir -p packages
        export V2RAY_VERSION="4.41.1-1"
        export V2RAY_REPO="https://github.com/kuoruan/openwrt-v2ray/releases/download/v${V2RAY_VERSION}/v2ray-core_${V2RAY_VERSION}_${ARCH}.ipk"
        wget -q -P packages/ ${V2RAY_REPO} || error "Failed to download file:v2ray.ipk !"
        ${ECMD} "src v2ray-core file:packages" >> repositories.conf
        # Install luci theme edge
        export EDGE_REPO="https://github.com/kiddin9/luci-theme-edge/releases/download/v2.5-19.07/luci-theme-edge_2.5_luci19.07.ipk"
        wget -q -P packages/ ${EDGE_REPO} || error "Failed to download file:luci-theme-edge.ipk !"
        ${ECMD} "src luci-theme-edge file:packages" >> repositories.conf
        ${SLP}
        ${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s " "${INFO}" "Install Libernet"
    ${PRIN} "%b" "${DONE}"
    ${SLP}
	${PRIN} " %b\\n" "${TICK}"
}

# Cook the image
OPENWRT_BUILD () {
    # Build
    ${PRIN} " %b %s ... \n" "${INFO}" "Ready to cook"
        sleep 2
        make image PROFILE="${INFO_MODEL}" \
        FILES="$(pwd)/files/" EXTRA_IMAGE_NAME="zerowrt" \
        PACKAGES="${ZEROWRT_PACKAGES}" DISABLED_SERVICES="${ZEROWRT_DISABLED}" || erroor "Failed to build image !"
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
    clear ; OPENWRT_SIZE
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
        OPENWRT_BUILD
    fi
}

main
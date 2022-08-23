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

error() {
    ${PRIN} "$1 ! ${CROSS}\n"
    exit
}

# Select OpenWrt version from official repository
OPENWRT_VERSION () {
    DIALOG_VERSION=$(whiptail --title "Openwrt Version" \
		--radiolist "Choose your version" ${R} ${C} 3 \
		"21.02.3" "Latest Stable Release" ON \
		"19.07.9" "Old Stable Release" OFF \
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
	export MODEL_2="Pi 2 (32 bit) compatible on pi 2B,2B+,3B,3B+,CM3,zero2,4B,400,cm4"
	export MODEL_3="Pi 3 (64 bit) compatible on pi 2Brev2,3B,3B+,CM3,zero2"
	export MODEL_4="Pi 4 (64 bit) compatible on pi 4B,400,CM4"

    whiptail --title "Raspberry Pi Model" \
		--radiolist "Choose your raspi model" ${R} 90 4 \
		"bcm2708" "${MODEL_1}" ON \
		"bcm2709" "${MODEL_2}"  OFF \
		"bcm2710" "${MODEL_3}"  OFF \
		"bcm2711" "${MODEL_4}"  OFF \
		2>model.txt

    if [ $? = 0 ] ; then
        export MODEL_ARCH=$(cat model.txt)
    else
        OPENWRT_VERSION
    fi

    if [[ ${MODEL_ARCH} = bcm2708 ]] ; then
        export INFO_MODEL="rpi"
        export ARCH="arm_arm1176jzf-s_vfp"
        export AKA_ARCH="arm32-v6"
        export SHORT_ARCH="armv6"
        export MODELL="${MODEL_1}"
    elif [[ ${MODEL_ARCH} = bcm2709 ]] ; then
		export INFO_MODEL="rpi-2"
        export ARCH="arm_cortex-a7_neon-vfpv4"
        export AKA_ARCH="arm32-v7a"
        export SHORT_ARCH="armv7"
        export MODELL="${MODEL_2}"
	elif [[ ${MODEL_ARCH} = bcm2710 ]] ; then
		export INFO_MODEL="rpi-3"
		export ARCH="aarch64_cortex-a53"
        export AKA_ARCH="arm64-v8a"
        export SHORT_ARCH="armv8"
        export MODELL="${MODEL_3}"
	elif [[ ${MODEL_ARCH} = bcm2711 ]] ; then
		export INFO_MODEL="rpi-4"
		export ARCH="aarch64_cortex-a72"
        export AKA_ARCH="arm64-v8a"
        export SHORT_ARCH="armv8"
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
        OPENWRT_MODEL
    fi
}

OPENWRT_ROOTFS () {
	DIALOG_ROOT=$(whiptail --title "Set partition size of /root" \
        --inputbox "Write size of /root [>300 Mb] :" ${R} ${C} "300" \
        3>&1 1>&2 2>&3)

    if [ $? = 0 ] ; then
		export ROOTFS=${DIALOG_ROOT}
    else
        OPENWRT_BOOTFS
    fi
}

OPENWRT_IPADDR () {
	DIALOG_IPADDR=$(whiptail --title "Set default ip address" \
        --inputbox "Write ip address openwrt :" ${R} ${C} "192.168.1.1" \
        3>&1 1>&2 2>&3)

    if [ $? = 0 ] ; then
		export IP_ADDR=${DIALOG_IPADDR}
    else
        OPENWRT_ROOTFS
    fi
}

OPENWRT_TUNNEL () {
    whiptail --title "Select tunnel package" \
		--checklist --separate-output "Choose your package" ${R} ${C} 4 \
		"Openclash" "" ON \
		"Openvpn" ""  OFF \
		"Wireguard" ""  OFF \
		"Xderm" ""  OFF \
		2>tunnel.txt

    while read dTunnel ; do
        case "$dTunnel" in
            Openclash)
                Openclash
            ;;
            Openvpn)
                Openvpn
            ;;
            Wireguard)
                Wireguard
            ;;
            Xderm)
                Xderm
            ;;
            *)
            ;;
        esac
    done < tunnel.txt
}

OPENWRT_ADDONS () {
    whiptail --title "Select addons package" \
		--checklist --separate-output "Choose your package" ${R} 90 3 \
		"Luci Theme Edge" "Aesthetic Theme :>" ON \
        "Modem Manager Utils" "Universal Driver For Modem Sierra EM7430, Fibocom L850, etc" OFF \
        "Fibocom" "Additional Fibocom Configuration" OFF \
		2>addons.txt

    while read dAddons ; do
        case "$dAddons" in
            Theme)
                Theme
            ;;
            mUtils)
                mUtils
            ;;
            Fibocom)
                Fibocom
            ;;
        esac
    done < addons.txt
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
        export DIR_TYPE="universal/"
        cp $(pwd)/${DIR_TYPE}/disabled.txt ${IMAGEBUILDER_DIR} || error "Failed to copy file:disabled.txt !"
        cp $(pwd)/${DIR_TYPE}/packages.txt ${IMAGEBUILDER_DIR} || error "Failed to copy file:packages.txt !"
        # export ZEROWRT_DISABLED="$(echo $(cat $(pwd)/${DIR_TYPE}/disabled.txt))"
    # Prepare data
    ${PRIN} " %b %s ... " "${INFO}" "Preparing data"
        mkdir -p ${ROOT_DIR} || error "Failed to create files/root directory !"
        # mkdir -p files/usr/lib/lua/luci/controller files/usr/lib/lua/luci/view  || error "Failed to create directory !"
        cp -arf $(pwd)/${DIR_TYPE}/data/* ${ROOT_DIR} || error "Failed to copy data !"
        chmod +x ${ROOT_DIR}/usr/bin/neofetch || error "Failed to chmod:neofetch"
        chmod +x ${ROOT_DIR}/usr/bin/hilink || error "Failed to chmod:hilink"
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
    # Add https://github.com/lrdrdn/my-opkg-repo
    ${PRIN} " %b %s ... " "${INFO}" "Add Additional Repository"
        # Disable Signature Verification
        sed -i 's/option check_signature/# option check_signature/g' repositories.conf
        # Generic
        ${ECMD} "src/gz custom_generic https://raw.githubusercontent.com/lrdrdn/my-opkg-repo/main/generic" >> repositories.conf
        # Architecture
        ${ECMD} "src/gz custom_arch https://raw.githubusercontent.com/lrdrdn/my-opkg-repo/main/${ARCH}" >> repositories.conf
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
}

Openclash () {
        # Install openclash
        ${PRIN} " %b %s ... " "${INFO}" "Preparing OpenClash"
            # Install luci-app-openclash
            export OC_Luci=$(curl -sL https://github.com/vernesong/OpenClash/releases \
            | grep 'luci-app-openclash_' \
            | sed -e 's/\"//g' -e 's/ //g' -e 's/rel=.*//g' -e 's#<ahref=#http://github.com#g' \
            | awk 'FNR <= 1')
            wget -q -P packages/ ${OC_Luci} || error "Failed to download file:luci-app-openclash.ipk !"
            ${ECMD} "src luci-app-openclash file:packages" >> repositories.conf
            cat >> packages.txt << EOF
coreutils
coreutils-nohup
iptables-mod-tproxy
iptables-mod-extra
libcap
libcap-bin
ruby
ruby-yaml
ip6tables-mod-nat
luci-app-openclash
EOF
            # Install Core Clash
            export OC_Core_Dir="files/etc/openclash/core"
            export OC_Core_Repo="https://raw.githubusercontent.com/vernesong/OpenClash/master/core-lateset"
            export OC_Premium_Version=$(echo $(curl -sL https://github.com/vernesong/OpenClash/raw/master/core_version | awk '{print $1}' ) | awk '{print $2}')
            mkdir -p ${OC_Core_Dir}
            # Core Meta
            wget -q -P ${OC_Core_Dir} ${OC_Core_Repo}/meta/clash-linux-${SHORT_ARCH}.tar.gz || error "Failed to download OpenClash Core"
            tar -xf ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}.tar.gz -C ${OC_Core_Dir} || error "Failed to install OpenClash Core"
            mv files/etc/openclash/core/clash files/etc/openclash/core/clash_meta || error "Failed to rename clash_meta"
            rm ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}.tar.gz
            # Core Premium
            wget -q -P ${OC_Core_Dir} ${OC_Core_Repo}/premium/clash-linux-${SHORT_ARCH}-${OC_Premium_Version}.gz || error "Failed to download OpenClash Core"
            gzip -dk ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}-${OC_Premium_Version}.gz || error "Failed to install OpenClash Core"
            mv ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}-${OC_Premium_Version} files/etc/openclash/core/clash_tun || error "Failed to rename clash_tun"
            rm ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}-${OC_Premium_Version}.gz
            # Core Dev
            wget -q -P ${OC_Core_Dir} ${OC_Core_Repo}/dev/clash-linux-${SHORT_ARCH}.tar.gz || error "Failed to download OpenClash Core"
            tar -xf ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}.tar.gz -C ${OC_Core_Dir} || error "Failed to install OpenClash Core"
            rm ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}.tar.gz
        ${SLP}
	    ${PRIN} "%b\\n" "${TICK}"

        # Install tiny file manager
        ${PRIN} " %b %s ... " "${INFO}" "Preparing Tiny File Manager"
            # Install requirements
            cat >> packages.txt << EOL
php7
php7-cgi
php7-mod-session
php7-mod-ctype
php7-mod-fileinfo
php7-mod-mbstring
iconv
EOL
            # Kick off TFM
            export TFM_Repo="https://github.com/noct99/blog.vpngame.com/raw/main/fileexplorer.zip"
            export TFM_Dir="files/www"
            wget -q -P ${TFM_Dir} ${TFM_Repo} || error "Cant download tiny file manager"
            unzip ${TFM_Dir}/fileexplorer.zip -d ${TFM_Dir}
            cat > files/usr/lib/lua/luci/controller/tinyfm.lua  << EOF
module("luci.controller.tinyfm", package.seeall)
function index()
entry({"admin","system","tinyfm"}, template("tinyfm"), _("File Explorer"), 55).leaf=true
end
EOF
            cat > files/usr/lib/lua/luci/view/tinyfm.htm  << EOL
<%+header%>
<div class="cbi-map">
<br>
<iframe id="tinyfm" style="width: 100%; min-height: 650px; border: none; border-radius: 2px;"></iframe>
</div>
<script type="text/javascript">
document.getElementById("tinyfm").src = "http://" + window.location.hostname + "/tinyfm.php";
</script>
<%+footer%>
EOL
        ${SLP}
        ${PRIN} "%b\\n" "${TICK}"
}

Openvpn () {
    ${PRIN} " %b %s ... " "${INFO}" "Preparing Openvpn"
    cat >> packages.txt << EOF
luci-app-openvpn
openssh-client
openvpn-openssl
openvpn-easy-rsa
stunnel
EOF
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
}

Wireguard () {
    ${PRIN} " %b %s ... " "${INFO}" "Preparing Wireguard"
    cat >> packages.txt << EOF
kmod-wireguard
luci-app-wireguard
luci-proto-wireguard
wireguard-tools
EOF
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
}

Xderm () {
    # Install xderm binaries
    ${PRIN} " %b %s ... \n" "${INFO}" "Installing xderm binaries"
        export XDERM_BIN="https://github.com/jakues/openwrt-proprietary/raw/main/xderm.txt"
        mkdir -p files/usr/bin
        mkdir -p files/bin
        wget -q ${XDERM_BIN} || error "Failed to download file:binaries.txt !"
            while IFS= read -r line ; do
                    if ! which ${line} > /dev/null 2>&1 ; then
                    bin="files/usr/bin/${line}"
                    ${ECMD} "\e[0;34mInstalling\e[0m ${line} ..."
                    wget -q -O "${bin}" "https://github.com/jakues/openwrt-proprietary/raw/main/${ARCH}/binaries/${line}" || error "Failed to download xderm binaries !"
                    chmod +x "${bin}" || error "Failed to chmod !"
                    fi
            done < xderm.txt
        mkdir -p packages
        export V2RAY_REPO=$(curl -sL https://github.com/kuoruan/openwrt-v2ray/releases/latest \
        | grep '/kuoruan/openwrt-v2ray/releases/download' \
        | sed -e 's/\"//g' -e 's/ //g' -e 's/rel=.*//g' -e 's#<ahref=#http://github.com#g' \
        | grep 'v2ray-core_' | grep ${ARCH})
        wget -q -P packages/ ${V2RAY_REPO} || error "Failed to download file:v2ray-core.ipk !"
        ${ECMD} "src v2ray-core file:packages" >> repositories.conf
        cat >> packages.txt << EOF
coreutils-base64
coreutils-timeout
httping
v2ray-core
procps-ng-ps
python3
python3-pip
openssh-client
openssl-util
php7
php7-cgi
php7-mod-session
https-dns-proxy
EOF
    ${PRIN} " %b %s " "${INFO}" "xderm binaries"
    ${PRIN} "%b" "${DONE}"
    ${SLP}
    ${PRIN} " %b\\n" "${TICK}"
    # Install xderm web
    ${PRIN} " %b %s ... \n" "${INFO}" "Installing xderm webpage"
        export XDERM_REPO="https://github.com/jakues/xderm-mini_GUI/raw/main"
        mkdir -p files/www/xderm files/www/xderm/js files/www/xderm/img files/www/xderm/log
        cat >> xderm << EOF
index.php
index.html
xderm-mini
login.php
header.php
config.txt
EOF
            while IFS= read -r line ; do
                    if ! which ${line} > /dev/null 2>&1 ; then
                    xderm_www="files/www/xderm/${line}"
                    ${ECMD} "\e[0;34mDownloading\e[0m ${line} ..."
                    wget -q -O ${xderm_www} ${XDERM_REPO}/${line} || error "Failed to download xderm binaries !"
                    fi
            done < xderm
        cat >> xderm-img << EOF
image.png
fav.ico
ico.png
background.jpg
EOF
            while IFS= read -r line ; do
                    if ! which ${line} > /dev/null 2>&1 ; then
                    xderm_img="files/www/xderm/img/${line}"
                    ${ECMD} "\e[0;34mDownloading\e[0m ${line} ..."
                    wget -q -O ${xderm_img} ${XDERM_REPO}/${line} || error "Failed to download xderm binaries !"
                    fi
            done < xderm-img
        wget -q -P files/www/xderm/js/ ${XDERM_REPO}/jquery-2.1.3.min.js || error "Failed to download xderm binaries !"
        wget -q -P files/usr/bin/ ${XDERM_REPO}/adds/xdrauth || error "Failed to download xderm binaries !"
        wget -q -P files/www/xderm/ ${XDERM_REPO}/adds/xdrtheme-blue-agus || error "Failed to download xderm binaries !"
        wget -q -P files/bin/ ${XDERM_REPO}/adds/xdrtool || error "Failed to download xderm binaries !"
        chmod +x files/usr/bin/xdrauth || error "Faild to change permission"
        chmod +x files/usr/bin/xdrtool || error "Faild to change permission"
        rm files/www/xderm/login.php files/www/xderm/header.php || error "Failed to remove xderm:login webpage"
        cat > files/usr/lib/lua/luci/controller/xderm.lua << EOF
module("luci.controller.xderm", package.seeall)
function index()
entry({"admin", "services", "xderm"}, template("xderm"), _("Xderm"), 2).leaf=true
end
EOF
        cat > files/usr/lib/lua/luci/view/xderm.htm << EOF
<%+header%>
<div class="cbi-map">
<iframe id="xderm" style="width: 100%; min-height: 800px; border: none; border-radius: 2px;"></iframe>
</div>
<script type="text/javascript">
document.getElementById("xderm").src = "http://" + window.location.hostname + "/xderm";
</script>
<%+footer%>
EOF
    ${PRIN} " %b %s " "${INFO}" "Install xderm"
    ${PRIN} "%b" "${DONE}"
    ${SLP}
    ${PRIN} " %b\\n" "${TICK}"
}

Theme () {
    # Install luci theme edge
    export EDGE_REPO=$(curl -sL https://github.com/kiddin9/luci-theme-edge/releases | grep 'luci-theme-edge_' | sed -e 's/\"//g' -e 's/ //g' -e 's/rel=.*//g' -e 's#<ahref=#http://github.com#g' | awk 'FNR <= 1')
    wget -q -P packages/ ${EDGE_REPO} || error "Failed to download file:luci-theme-edge.ipk !"
    ${ECMD} "src luci-theme-edge file:packages" >> repositories.conf
    ${ECMD} "luci-theme-edge" >> packages.txt
}

mUtils () {
    # Install Universal Package for Modem Manager
    ${PRIN} " %b %s ... " "${INFO}" "Preparing Packages for Modem Utilty"
    cat >> packages.txt << EOF
atinout
kmod-mii
kmod-usb-acm
kmod-usb-net-qmi-wwan
kmod-usb-serial-qualcomm
kmod-usb-net-cdc-mbim
luci-app-atinout-mod
luci-app-sms-tools
luci-proto-modemmanager
luci-proto-ncm
luci-proto-qmi
qmi-utils
umbim
uqmi
modemmanager
minicom
picocom
xmm-modem
EOF
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
}

Fibocom () {
    # Install Package for Modem Fibocom L850 GL & L860 GL
    ${PRIN} " %b %s ... " "${INFO}" "Preparing Configuration for Fibocom Modem"
    cat > files/etc/config/xmm-modem << EOI
config xmm-modem
    option device '/dev/ttyACM0'
    option apn 'internet'
    option enable '1'
EOI
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
}

old () {
    if [[ ${OPENWRT_VERZION} = 19.* || ${OPENWRT_VERZION} = 18.* ]] ; then
        ${PRIN} " %b %s " "${INFO}" "Detected old version openwrt"
            # Download bcm27xx-userland manual
            export USERLAND_REPO="https://github.com/jakues/openwrt-proprietary/raw/main/${ARCH}/packages/bcm27xx-userland.ipk"
            wget -q -P packages/ ${USERLAND_REPO} || error "Failed to download file:bcm27xx-userland.ipk"
            ${ECMD} "src bcm27xx-userland file:packages" >> repositories.conf
            # Download libcap-bin
            export LIBCAP_REPO="https://github.com/jakues/openwrt-proprietary/raw/main/${ARCH}/packages/libcap-bin.ipk"
            wget -q -P packages/ ${LIBCAP_REPO} || error "Failed to download file:libcap-bin.ipk"
            ${ECMD} "src libcap-bin file:packages" >> repositories.conf
            # Configure network
            export NETWORK_DIR="files/etc/uci-defaults/99_configure_network"
            rm files/etc/config/network
            cat > ${NETWORK_DIR} << "EOF"
uci -q batch << EOI
set network.lan=interface
set network.lan.type='bridge'
set network.lan.netmask='255.255.255.0'
set network.lan.proto='static'
set network.lan.ifname='eth0'
set network.lan.ipaddr='4.3.2.1'
set network.tun0=interface
set network.tun0.proto='none'
set network.tun0.ifname='tun0'
set network.wan=interface
set network.wan.proto='dhcp'
set network.wan.ifname='eth1
commit network
EOI
EOF
        sed -i -e "s/4.3.2.1/${IP_ADDR}/" ${NETWORK_DIR} || error "Failed to change openwrt ip address" 
        ${SLP}
        ${PRIN} "%b\\n" "${TICK}"
    fi
}

other () {
    export LAN_DIR="files/etc/uci-defaults/99_configure_lan"
    cat > ${LAN_DIR} << "EOF"
uci -q batch << EOI
set network.lan.ifname="`uci get network.lan.ifname` usb0"
commit network
EOI
echo "dtoverlay=dwc2" >> /boot/config.txt
EOF
}

# Cook the image
OPENWRT_BUILD () {
    # Build
    ${PRIN} " %b %s ... \n" "${INFO}" "Ready to cook"
        export ZEROWRT_PACKAGES="$(echo $(cat packages.txt))"
        export ZEROWRT_DISABLED="$(echo $(cat disabled.txt))"
        ${SLP}
        make image PROFILE="${INFO_MODEL}" \
        FILES="$(pwd)/files/" \
        EXTRA_IMAGE_NAME="zerowrt" \
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
    OPENWRT_TUNNEL
    OPENWRT_ADDONS
    old
    other
    OPENWRT_BUILD
}

main
#!/bin/bash
#================================================================================================
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of the make OpenWrt for Amlogic s9xxx tv box
# https://github.com/ophub/amlogic-s9xxx-openwrt
#
# Description: Build OpenWrt with Image Builder
# Copyright (C) 2021- https://github.com/unifreq/openwrt_packit
# Copyright (C) 2021- https://github.com/ophub/amlogic-s9xxx-openwrt
#
# Download from: https://downloads.openwrt.org/releases
# Documentation: https://openwrt.org/docs/guide-user/additional-software/imagebuilder
# Instructions:  Download OpenWrt firmware from the official OpenWrt,
#                Use Image Builder to add packages, lib, theme, app and i18n, etc.
#
# Command: ./router-config/openwrt-imagebuilder/imagebuilder.sh <branch>
#          ./router-config/openwrt-imagebuilder/imagebuilder.sh 21.02.3
#
#======================================== Functions list ========================================
#
# error_msg               : Output error message
# download_imagebuilder   : Downloading OpenWrt ImageBuilder
# adjust_settings         : Adjust related file settings
# custom_packages         : Add custom packages
# custom_files            : Add custom files
# custom_config           : Add custom config
# rebuild_firmware        : Rebuild_firmware
# clean_tmp               : Clear temporary files
#
#================================ Set make environment variables ================================
#
# Set default parameters
make_path="${PWD}"
imagebuilder_path="${make_path}/openwrt"
custom_files_path="${make_path}/config/files"
config_file_path="${make_path}/config/imgbuilder/.config"
# Set default parameters
STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
WARNING="[\033[93m WARNING \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"
#
#================================================================================================

# Encountered a serious error, abort the script execution
error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

# Downloading OpenWrt ImageBuilder
download_imagebuilder() {
    echo -e "${STEPS} Start downloading OpenWrt files..."
    # Downloading imagebuilder files
    # Download example: https://downloads.openwrt.org/releases/21.02.3/targets/armvirt/64/openwrt-imagebuilder-21.02.3-armvirt-64.Linux-x86_64.tar.xz    #

    # Var configuration
    if [[ ${rebuild_branch} = 18.* || ${rebuild_branch} = 19.* ]]; then
        export openwrt_rpi="brcm2708"
    elif [[ ${rebuild_branch} = 22.* || ${rebuild_branch} = 23.* ]]; then
        export openwrt_rpi="bcm27xx"
    fi

    if [[ ${rebuild_branch} = 23.* ]]; then
        # default set to 7 not 8
        export PHP_VERSION="7"
    else
        export PHP_VERSION="7"
    fi

    if [[ ${rpi_board} = bcm2708 ]]; then
        export ARCH="arm_arm1176jzf-s_vfp"
        export MODEL="rpi"
        export SHORT_ARCH="armv6"
    elif [[ ${rpi_board} = bcm2709 ]]; then
        export ARCH="arm_cortex-a7_neon-vfpv4"
        export MODEL="rpi-2"
        export SHORT_ARCH="armv7"
    elif [[ ${rpi_board} = bcm2710 ]]; then
        export ARCH="aarch64_cortex-a53"
        export MODEL="rpi-3"
        export SHORT_ARCH="arm64"
    elif [[ ${rpi_board} = bcm2711 ]]; then
        export ARCH="aarch64_cortex-a72"
        export MODEL="rpi-4"
        export SHORT_ARCH="arm64"
    fi

    # download_file="https://downloads.openwrt.org/releases/${rebuild_branch}/targets/armvirt/64/openwrt-imagebuilder-${rebuild_branch}-armvirt-64.Linux-x86_64.tar.xz"
    download_file="https://downloads.openwrt.org/releases/${rebuild_branch}/targets/${openwrt_rpi}/${rpi_board}/openwrt-imagebuilder-${rebuild_branch}-${openwrt_rpi}-${rpi_board}.Linux-x86_64.tar.xz"
    wget -q ${download_file}
    [[ "${?}" -eq "0" ]] || error_msg "Wget download failed: [ ${download_file} ]"

    # Unzip and change the directory name
    tar -xJf openwrt-imagebuilder-* && sync && rm -f openwrt-imagebuilder-*.tar.xz
    mv -f openwrt-imagebuilder-* openwrt

    # For packages.txt and disabled.txt
    cp ${make_path}/config/packages.txt ${imagebuilder_path}
    cp ${make_path}/config/disabled.txt ${imagebuilder_path}

    sync && sleep 3
    echo -e "${INFO} [ ${make_path} ] directory status: $(ls . -l 2>/dev/null)"
}

# Adjust related files in the ImageBuilder directory
adjust_settings() {
    cd ${imagebuilder_path}

    # For .config file
    [[ -s ".config" ]] && {
        echo -e "${STEPS} Start adjusting .config file settings..."
        # Root filesystem archives
        # sed -i "s|CONFIG_TARGET_ROOTFS_CPIOGZ=.*|# CONFIG_TARGET_ROOTFS_CPIOGZ is not set|g" .config
        # Root filesystem images
        sed -i "s|CONFIG_TARGET_ROOTFS_SQUASHFS=.*|# CONFIG_TARGET_ROOTFS_SQUASHFS is not set|g" .config
        #
        sed -i -e "s/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=${bootfs}/" .config
        sed -i -e "s/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=${rootfs}/" .config
    }

    sync && sleep 3
    echo -e "${INFO} [ openwrt ] directory status: $(ls -al 2>/dev/null)"
}

# Add custom packages
# If there is a custom package or ipk you would prefer to use create a [ packages ] directory,
# If one does not exist and place your custom ipk within this directory.
custom_packages() {
    cd ${imagebuilder_path}

    echo -e "${STEPS} Start adding custom packages..."
    # Create a [ packages ] directory
    [[ -d "packages" ]] || mkdir packages

    # Download luci-app-openclash
    OC_Version=$(curl -sL https://github.com/vernesong/OpenClash/tags |
        grep 'v0.4' |
        sed -e 's/\"//g' -e 's/ //g' -e 's/rel=.*//g' -e 's#<ahref=##g' -e 's/>//g' |
        sed -e 's#/vernesong/OpenClash/archive/refs/tags/##g' |
        sed -e 's#.zip##g' -e 's#v##g' |
        sed -e 's#<aclass=Link--mutedhref=##g' -e 's/>//g' |
        awk 'FNR == 4')
    OC_Luci="https://github.com/vernesong/OpenClash/releases/download/v${OC_Version}/luci-app-openclash_${OC_Version}_all.ipk"
    wget -q -P packages/ ${OC_Luci}
    [[ "${?}" -eq "0" ]] && echo -e "${INFO} The [ ${OC_Luci} ] is downloaded successfully."
    # Add Requirements for OpenClash
    echo "src luci-app-openclash file:packages" >> repositories.conf
    cat >>packages.txt << EOF

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
    # Add Requirements for TinyFileManager
    if [[ ${PHP_VERSION} = 8 ]]; then
        cat >>packages.txt << EOL

php8
php8-cli
php8-cgi
php8-mod-session
php8-mod-ctype
php8-mod-fileinfo
php8-mod-mbstring
php8-mod-json
php8-mod-iconv
php8-mod-zip
EOL
    else
        cat >>packages.txt << EOL

    php7
    php7-cli
    php7-cgi
    php7-mod-session
    php7-mod-ctype
    php7-mod-fileinfo
    php7-mod-mbstring
    php7-mod-json
    php7-mod-iconv
    php7-mod-zip
    iconv
EOL
    fi

    # Add tano theme
    Tano_Repo="https://github.com/jakues/luci-theme-tano/releases/download/0.1/luci-theme-tano_0.1_all.ipk"
    wget -q -P packages/ ${Tano_Repo}
    [[ "${?}" -eq "0" ]] && echo -e "${INFO} The [ ${Tano_Repo} ] is downloaded successfully."
    echo "src luci-theme-tano file:packages" >> repositories.conf

    sync && sleep 3
    echo -e "${INFO} [ packages ] directory status: $(ls packages -l 2>/dev/null)"
}

# Add custom files
# The FILES variable allows custom configuration files to be included in images built with Image Builder.
# The [ files ] directory should be placed in the Image Builder root directory where you issue the make command.
custom_files() {
    cd ${imagebuilder_path}

    [[ -d "${custom_files_path}" ]] && {
        echo -e "${STEPS} Start adding custom files..."
        # Copy custom files
        [[ -d "files" ]] || mkdir -p files
        cp -rf ${custom_files_path}/* files
        #
        # custom files here
        #
        # Change Permission neofetch and other
        chmod +x files/usr/bin/neofetch files/usr/bin/hilink files/etc/zshinit || error_msg "Please check the path file"
        sed -i -e "s/4.3.2.1/${addr}/g" files/etc/config/network
        # Clone OhMyZsh
        OMZ_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
        git clone -q ${OMZ_REPO} files/root/.oh-my-zsh
        # Add Additional Custom Repo's
        # Disable Signature Verification
        sed -i 's/option check_signature/# option check_signature/g' repositories.conf
        # Add Repo 21.02.3 packages
        echo "src/gz old_packages_repos https://downloads.openwrt.org/releases/21.02.3/packages/${ARCH}/packages/" >> repositories.conf
        # Add Repo 21.02.3 base
        echo "src/gz old_base_repos https://downloads.openwrt.org/releases/21.02.3/packages/${ARCH}/base/" >> repositories.conf
        # Add lrdrdn Generic repo
        echo "src/gz custom_generic https://raw.githubusercontent.com/lrdrdn/my-opkg-repo/main/generic" >> repositories.conf
        # Add lrdrdn Architecture repo
        echo "src/gz custom_arch https://raw.githubusercontent.com/lrdrdn/my-opkg-repo/main/${ARCH}" >> repositories.conf
        #
        # Install Core Clash
        OC_Core_Dir="files/etc/openclash/core"
        OC_Core_Repo="https://raw.githubusercontent.com/vernesong/OpenClash/refs/heads/core/master"
        OC_Premium_Version=$(echo $(curl -sL https://github.com/vernesong/OpenClash/raw/master/core_version | awk '{print $1}') | awk '{print $2}')
        mkdir -p ${OC_Core_Dir}
        # Core Meta
        # example https://github.com/vernesong/OpenClash/raw/master/core-lateset/meta/clash-linux-armv7.tar.gz
        wget -q -P ${OC_Core_Dir} ${OC_Core_Repo}/meta/clash-linux-${SHORT_ARCH}.tar.gz || error_msg "Failed to download OpenClash Core [meta]"
        tar -xf ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}.tar.gz -C ${OC_Core_Dir} || error_msg "Failed to install OpenClash Core"
        mv files/etc/openclash/core/clash files/etc/openclash/core/clash_meta || error_msg "Failed to rename clash_meta"
        rm ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}.tar.gz
        # Core Premium
        wget -q -P ${OC_Core_Dir} ${OC_Core_Repo}/premium/clash-linux-${SHORT_ARCH}-${OC_Premium_Version}.gz || error_msg "Failed to download OpenClash Core [premium]"
        gzip -dk ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}-${OC_Premium_Version}.gz || error_msg "Failed to install OpenClash Core"
        mv ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}-${OC_Premium_Version} files/etc/openclash/core/clash_tun || error_msg "Failed to rename clash_tun"
        rm ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}-${OC_Premium_Version}.gz
        # Core Dev
        wget -q -P ${OC_Core_Dir} ${OC_Core_Repo}/dev/clash-linux-${SHORT_ARCH}.tar.gz || error_msg "Failed to download OpenClash Core [dev]"
        tar -xf ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}.tar.gz -C ${OC_Core_Dir} || error_msg "Failed to install OpenClash Core"
        rm ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}.tar.gz
        #
        # Install TinyFileManager
        TFM_Repo="https://github.com/jakues/tinyfilemanager/raw/master/tinyfilemanager.php"
        TFM_Conf="https://github.com/jakues/tinyfilemanager/raw/master/config-sample.php"
        TFM_Dir="files/www"
        wget -q -P ${TFM_Dir} ${TFM_Repo} || error_msg "Cant download tiny file manager"
        wget -q -O ${TFM_Dir}/config.php ${TFM_Conf} || error_msg "Cant download tiny file manager config"
        sed -i -e 's/$use_auth = true;/$use_auth = false;/g' \
            -e 's#Etc/UTC#Asia/Jakarta#g' \
            -e 's/?>//g' \
            -e 's#$root_path*#// $root_path*#g' ${TFM_Dir}/config.php
        cat >>${TFM_Dir}/config.php <<EOI

root_path = '../'

?>
EOI
        sed -i -e 's#root_path#$root_path#g' ${TFM_Dir}/config.php
        TFM_Lua_Dir="files/usr/lib/lua/luci/controller"
        TFM_Html_Dir="files/usr/lib/lua/luci/view"
        mkdir -p ${TFM_Lua_Dir}
        cat >${TFM_Lua_Dir}/tinyfm.lua <<EOF
module("luci.controller.tinyfm", package.seeall)
function index()
entry({"admin","system","tinyfm"}, template("tinyfm"), _("File Explorer"), 55).leaf=true
end
EOF
        mkdir -p ${TFM_Html_Dir}
        cat >${TFM_Html_Dir}/tinyfm.htm <<EOL
<%+header%>
<div class="cbi-map">
<br>
<iframe id="tinyfm" style="width: 100%; min-height: 650px; border: none; border-radius: 2px;"></iframe>
</div>
<script type="text/javascript">
document.getElementById("tinyfm").src = "http://" + window.location.hostname + "/tinyfilemanager.php";
</script>
<%+footer%>
EOL

        # Set tano theme on branch 21.+
        if [[ ${rebuild_branch} = 21.* || ${rebuild_branch} = 22.* ]] ; then
            cat > files/etc/uci-defaults/30_luci-theme-tano << EOL
#!/bin/sh

	uci get luci.themes.Tano >/dev/null 2>&1 || \
	uci batch <<-EOF
		set luci.themes.Tano=/luci-static/tano
		set luci.main.mediaurlbase=/luci-static/tano
		commit luci
	EOF

exit 0
EOL
        fi

        # Set brcm-userland for old branch


        sync && sleep 3
        echo -e "${INFO} [ files ] directory status: $(ls files -l 2>/dev/null)"
    }
}

# Rebuild OpenWrt firmware
rebuild_firmware() {
    cd ${imagebuilder_path}

    echo -e "${STEPS} Start building OpenWrt with Image Builder..."
    export ZEROWRT_PACKAGES="$(echo $(cat packages.txt))"
    export ZEROWRT_DISABLED="$(echo $(cat disabled.txt))"

    # Rebuild firmware
    make image PROFILE="${MODEL}" \
        FILES="files/" \
        PACKAGES="${ZEROWRT_PACKAGES}" \
        DISABLED_SERVICES="${ZEROWRT_DISABLED}"

    # Store firmware on results dir
    cd ..
    mkdir -p results
    cp -r ${imagebuilder_path}/bin/targets/${openwrt_rpi}/${rpi_board} results
    openwrt_outpath=results/*/

    sync && sleep 3
    echo -e "${INFO} [ results/${rpi_board} ] directory status: $(ls results/${rpi_board} -l 2>/dev/null)"
}

clean_tmp() {
    echo -e "${STEPS} Clean Up Temporary File/Folder"
    rm -rf ${imagebuilder_path}

    sync && sleep 3
    echo -e "${INFO} [ ${make_path} ] directory status: $(ls . -l 2>/dev/null)"
    echo -e "${SUCCESS} Build for ${MODEL} is successful, the current path: [ ${PWD} ]"
}

main() {
    # Perform related operations
    download_imagebuilder
    adjust_settings
    custom_packages
    custom_files
    rebuild_firmware
    clean_tmp
}

#
# Show welcome message
echo -e "${STEPS} Welcome to Rebuild OpenWrt Using the Image Builder."
export rebuild_branch="${1}"
export rpi_board="${2}"
export bootfs="${3}"
export rootfs="${4}"
export addr="${5}"
export all_board=(
    "bcm2708"
    "bcm2709"
    "bcm2710"
    "bcm2711"
)
echo -e "${INFO} Rebuild path: [ ${PWD} ]"
echo -e "${INFO} Rebuild branch: [ ${rebuild_branch} ]"
# kick off
if [[ "${rpi_board}" == "all" ]]; then
    echo -e "${INFO} Multi build detected"
    for i in ${all_board[*]}; do
        rpi_board=${i}
        main
    done
else
    echo -e "${INFO} Single build detected"
    main
fi
# Git env
echo -e "Output environment variables."
echo "MODEL=${MODEL}" >> ${GITHUB_ENV}
echo "IP_ADDRESS=${addr}" >> ${GITHUB_ENV}
echo "PACKAGED_OUTPUTPATH=${openwrt_outpath}" >> ${GITHUB_ENV}
echo "PACKAGED_OUTPUTDATE=$(date +"%m.%d.%H%M")" >> ${GITHUB_ENV}
echo "PACKAGED_STATUS=success" >> ${GITHUB_ENV}
# Show server end information
echo -e "Server space usage after compilation: \n$(df -hT ${make_path}) \n"
# All process completed
wait

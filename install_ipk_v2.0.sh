#!/bin/sh
# author: skinnyshy
# 脚本说明：用于每次升级版本之后安装常用软件，包括：openclash、Glinjector、argon主题、istore等

# 执行一次更新操作
opkg_update_once() {
    if [ -z "$OPKG_UPDATED" ]; then
        opkg update
        OPKG_UPDATED=1
    fi
}

is_installed() {
	for pkg in "$@"; do
		if opkg list-installed "$pkg" 2>/dev/null | grep -qi "^$pkg "; then
			return 0
		fi
	done
	return 1
}

install_if_missing() {
	name="$1"
	install_func="$2"
	shift 2

	if is_installed "$@"; then
		echo "$name already installed!!"
	else
		"$install_func"
	fi
}

ChangeMirror(){
	cp  /etc/opkg/distfeeds.conf  /etc/opkg/distfeeds.conf-$(date +%Y-%m-%d) || exit 1
	cat> /etc/opkg/distfeeds.conf << EOF
src/gz core https://fw.gl-inet.com/releases/v24.x/24.10.2/mediatek/filogic
src/gz base https://mirrors.vsean.net/openwrt/releases/24.10.2/packages/aarch64_cortex-a53/base
src/gz luci https://mirrors.vsean.net/openwrt/releases/24.10.2/packages/aarch64_cortex-a53/luci
src/gz packages https://mirrors.vsean.net/openwrt/releases/24.10.2/packages/aarch64_cortex-a53/packages
src/gz routing https://mirrors.vsean.net/openwrt/releases/24.10.2/packages/aarch64_cortex-a53/routing
src/gz telephony https://mirrors.vsean.net/openwrt/releases/24.10.2/packages/aarch64_cortex-a53/telephony
EOF
}


OpClashInstall() {
	mkdir -p /tmp/openclash || exit 2
	cd /tmp/openclash || exit 2
	# 使用wget下载经过加速的0.47.028版本的
	wget --no-check-certificate  -O openclash.ipk https://gh-proxy.org/https://github.com/vernesong/OpenClash/releases/download/v0.47.028/luci-app-openclash_0.47.028_all.ipk || curl -k -o openclash.ipk https://gh-proxy.org/https://github.com/vernesong/OpenClash/releases/download/v0.47.028/luci-app-openclash_0.47.028_all.ipk
	# 判断当前是否为nftables
	if [ "$(readlink /usr/sbin/iptables)" = "/usr/sbin/xtables-nft-multi" ]; then 
		# openwrt23之后默认使用nftables使用下面的命令进行安装,默认使用opkg管理器
		opkg_update_once
		opkg install bash dnsmasq-full curl ca-bundle ip-full ruby ruby-yaml kmod-tun kmod-inet-diag unzip kmod-nft-tproxy luci-compat luci luci-base || {
		    echo "错误: 依赖包安装失败"
		    exit 2
		}
		opkg install /tmp/openclash/openclash.ipk

	else 
		opkg_update_once
		opkg install bash iptables dnsmasq-full curl ca-bundle ipset ip-full iptables-mod-tproxy iptables-mod-extra ruby ruby-yaml kmod-tun kmod-inet-diag unzip luci-compat luci luci-base || {
		    echo "错误: 依赖包安装失败"
		    exit 2
		}
		opkg install /tmp/openclash/openclash.ipk
	fi
}

DadeInstall() {
	wget -O - https://gh-proxy.org/https://raw.githubusercontent.com/kenzok8/openwrt-daede/refs/heads/main/scripts/install.sh | ash
}

GlinjectorIns() {
	mkdir -p /tmp/glinjector || exit 3
	cd /tmp/glinjector || exit 3
	wget --no-check-certificate  -O glinjector.ipk https://gh-proxy.org/https://github.com/skinnyshy/mt3000repo/raw/main/glinjector/glinjector_3.0.7-8_all.ipk || curl -k -o glinjector.ipk https://gh-proxy.org/https://github.com/skinnyshy/mt3000repo/raw/main/glinjector/glinjector_3.0.7-8_all.ipk
	opkg_update_once
	opkg install *.ipk 
}

ArgonInstall() {
	opkg_update_once
	opkg install luci-compat luci-lib-ipkg || {
		    echo "错误: 依赖包安装失败"
		    exit 4
		}
	mkdir -p /tmp/argon || exit 4
	cd /tmp/argon || exit 4
	wget --no-check-certificate -O luci-app-argon-config.ipk https://gh-proxy.org/https://github.com/skinnyshy/mt3000repo/raw/main/luci-argon-theme/luci-app-argon-config_2.4.7_all.ipk || curl -k -o luci-app-argon-config.ipk https://gh-proxy.org/https://github.com/skinnyshy/mt3000repo/raw/main/luci-argon-theme/luci-app-argon-config_2.4.7_all.ipk
	wget --no-check-certificate -O luci-theme-argon.ipk https://gh-proxy.org/https://github.com/skinnyshy/mt3000repo/raw/main/luci-argon-theme/luci-theme-argon_2.4.7_all.ipk || curl -k -o luci-theme-argon.ipk https://gh-proxy.org/https://github.com/skinnyshy/mt3000repo/raw/main/luci-argon-theme/luci-theme-argon_2.4.7_all.ipk
	opkg install ./*.ipk
}

IstoreInstall() {
	opkg_update_once
	cd /tmp
	wget https://gh-proxy.org/https://github.com/linkease/openwrt-app-actions/raw/main/applications/luci-app-systools/root/usr/share/systools/istore-reinstall.run || exit 5
	chmod 755 istore-reinstall.run
	./istore-reinstall.run
}

EasytierIns() {
	mkdir -p /tmp/easytier || exit 5
	cd /tmp/easytier
	wget --no-check-certificate -O easytier.zip https://gh-proxy.org/https://github.com/skinnyshy/mt3000repo/raw/main/easytier/EasyTier-v2.6.4-aarch64_cortex-a53-22.03.7.zip|| curl -k -o easytier.zip https://gh-proxy.org/https://github.com/skinnyshy/mt3000repo/raw/main/easytier/EasyTier-v2.6.4-aarch64_cortex-a53-22.03.7.zip
	unzip easytier.zip
	opkg_update_once
	opkg install ./*.ipk || exit 5

}
Cleanup() {
	read -p "是否要清空/tmp下的安装临时目录？(y or n)" ans
	case "$ans" in 
		y)
			# 检查目录存在后删除，避免错误信息
		    [ -d /tmp/openclash ] && rm -rf /tmp/openclash
		    [ -d /tmp/glinjector ] && rm -rf /tmp/glinjector
		    [ -d /tmp/argon ] && rm -rf /tmp/argon
		    [ -d /tmp/easytier ] && rm -rf /tmp/easytier
		    echo "安装临时目录已清理！"
			;;
		n)
			echo "安装临时目录未清理，下次重启后自动清理！"
			;;
		*)
			echo "输入不正确，请重新输入"
			Cleanup
			;;
	esac
}
main() {
	while true; do
		echo "=============================="
		echo "请选择要安装的软件："
		echo "  1) OpenClash"
		echo "  2) Glinjector"
		echo "  3) daed"
		echo "  4) Argon 主题"
		echo "  5) iStore"
		echo "  6) EasyTier"
		echo "  0) 退出"
		echo "=============================="
		read -p "请输入数字后回车: " choice

		case "$choice" in
			1)
				install_if_missing "openclash" OpClashInstall luci-app-openclash
				Cleanup
				;;
			2)
				install_if_missing "glinjector" GlinjectorIns glinjector
				Cleanup
				;;
			3)
				install_if_missing "daed" DadeInstall daed luci-app-daed
				Cleanup
				;;
			4)
				install_if_missing "argontheme" ArgonInstall luci-theme-argon luci-app-argon-config
				Cleanup
				;;
			5)
				install_if_missing "istore" IstoreInstall app-store luci-app-store
				Cleanup
				;;
			6)
				install_if_missing "easytier" EasytierIns easytier luci-app-easytier
				Cleanup
				;;
			0)
				echo "已退出。"
				exit 0
				;;
			*)
				echo "输入不正确，请输入 0-6。"
				;;
		esac
	done
}

main

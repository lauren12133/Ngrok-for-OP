#!/bin/bash

# 控制台字体
red(){
	echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
	echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
	echo -e "\033[33m\033[01m$1\033[0m"
}

archAffix(){
	cpuArch=$(uname -m)
	case "$cpuArch" in
		i686 | i386) cpuArch='386' ;;
		x86_64 | amd64) cpuArch='amd64' ;;
		armv5tel | arm6l | armv7 | armv7l) cpuArch='arm' ;;
		armv8 | aarch64) cpuArch='arm64' ;;
		*) red "不支持的CPU架构！" && exit 1 ;;
	esac
}


back2menu(){
	green "所选操作执行完成"
	read -p "请输入“y”退出，或按任意键回到主菜单：" back2menuInput
	case "$back2menuInput" in
		y) exit 1 ;;
		*) menu ;;
	esac
}

getNgrokAddress(){
	if [ $httptcp == "tcp" ]; then
		tcpNgrok=$(curl --silent --show-error http://127.0.0.1:4040/api/tunnels | sed -nE 's/.*public_url":"tcp:..([^"]*).*/\1/p')
		green "隧道启动成功！当前TCP隧道地址为：$tcpNgrok"
	fi
	if [ $httptcp == "http" ]; then
		httpNgrok=$(curl --silent --show-error http://127.0.0.1:4040/api/tunnels | sed -nE 's/.*public_url":"http:..([^"]*).*/\1/p')
		httpsNgrok=$(curl --silent --show-error http://127.0.0.1:4040/api/tunnels | sed -nE 's/.*public_url":"https..([^"]*).*/\1/p')
		green "隧道启动成功！"
		yellow "当前隧道HTTP地址为：http://$httpNgrok"
		yellow "当前隧道HTTPS地址为：https://$httpsNgrok"
		yellow "如未获取重新启动即可"
	fi
}

download_ngrok(){
	wget -N https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-$cpuArch.tgz
	tar -xzvf ngrok-stable-linux-$cpuArch.tgz -C /usr/bin
	green "Ngrok 程序包已安装成功"
	back2menu
}

ngrok_authtoken(){
	read -p "请输入Ngrok官方网站的Authtoken：" authtoken
	[ -z $authtoken ] && red "无输入Authtoken，授权过程中断！" && back2menu
	ngrok authtoken $authtoken
	green "Ngrok Authtoken授权成功"
	back2menu
}

select_region(){
	echo "1. 美国 (us)"
	echo "2. 德国 (eu)"
	echo "3. 新加坡 (ap)"
	echo "4. 澳大利亚 (au)"
	echo "5. 南美洲 (sa)"
	echo "6. 日本 (jp)"
	echo "7. 印度 (in)"
	read -p "请选择Ngrok服务器区域（输入1-7内对应的编号，默认为US）：" ngrok_region
	case "$ngrok_region" in
		2 ) ngrok_region="eu" ;;
		3 ) ngrok_region="ap" ;;
		4 ) ngrok_region="au" ;;
		5 ) ngrok_region="sa" ;;
		6 ) ngrok_region="jp" ;;
		7 ) ngrok_region="in" ;;
		*) ngrok_region="us" ;;
	esac
}

runTunnel(){
	select_region
	read -p "请输入你所使用的设备ip（默认127.0.0.1）：" ip
	[ -z $ip ] && ip="127.0.0.1"
	read -p "请输入你所使用的协议（默认HTTP）：" httptcp
	[ -z $httptcp ] && httptcp="http"
	read -p "请输入反代端口（默认80）：" tunnelPort
	[ -z $tunnelPort ] && tunnelPort=80
	screen -USdm screen4ngrok ngrok $httptcp $ip:$tunnelPort -region $ngrok_region
	yellow "等待5秒，获取Ngrok的外网地址 "
	sleep 5
	getNgrokAddress
	back2menu
}

killTunnel(){
	screen -S screen4ngrok -X quit
	green "隧道停止成功！"
}

uninstall(){
	rm -rf /usr/bin/ngrok
	rm -rf /root/ngrok-stable-linux-$cpuArch.tgz ngrok .ngrok2 ngrok.sh
	sed -i '/ngrok/d' /etc/rc.local
	green "Ngrok 程序包已卸载成功"
	back2menu
}

start(){
     select_region
	read -p "请输入你所使用的设备ip（默认127.0.0.1）：" ip
	[ -z $ip ] && ip="127.0.0.1"
	read -p "请输入你所使用的协议（默认HTTP）：" httptcp
	[ -z $httptcp ] && httptcp="http"
	read -p "请输入反代端口（默认80）：" tunnelPort
	[ -z $tunnelPort ] && tunnelPort=80
	sed -i '/exit/d' /etc/rc.local
	echo screen -USdm screen4ngrok ngrok $httptcp $ip:$tunnelPort -region $ngrok_region >> /etc/rc.local
	yellow "自启配置完成，配置文件在/etc/rc.local 可在openwrt启动项页面最下方查看 "
	yellow "获取外网地址请登录https://dashboard.ngrok.com/cloud-edge/status Ngrok官网查看 "
	back2menu
}

menu(){
	clear
	red "=================================="
	echo "                           "
	red "   Ngrok openwrt 内网穿透一键脚本       "
	echo "                           "
	red "=================================="
	echo "                           "
	green "1. 安装/更新Ngrok程序包"
	green "2. 授权Ngrok账号"
	green "3. 启用隧道"
	green "4. 停用隧道"
	green "5. 卸载Ngrok程序包"
	green "6. 更新脚本"
	green "7. 开机自启"
	green "0. 退出"
	echo "         "
	read -p "请输入数字:" NumberInput
	case "$NumberInput" in
		1) download_ngrok ;;
		2) ngrok_authtoken ;;
		3) runTunnel ;;
		4) killTunnel ;;
		5) uninstall ;;
		6) rm -rf /root/ngrok.sh && wget https://raw.githubusercontent.com/lauren12133/Ngrok-1key/master/ngrok.sh && sh ngrok.sh ;;
		7) start ;;
		*) exit 1 ;;
	esac
}

archAffix
menu

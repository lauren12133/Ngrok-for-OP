#!/bin/bash
"请在root用户下运行脚本"

#检查设备cpu型号
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

#下载Ngrok
download_ngrok(){
	wget -N https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-$cpuArch.tgz
	tar -xzvf ngrok-stable-linux-$cpuArch.tgz -C /usr/bin
  "Ngrok 程序包已安装成功"
}

ngrok_authtoken(){
	read -p "请输入Ngrok官方网站的Authtoken：" authtoken
	[ -z $authtoken ] && red "无输入Authtoken，授权过程中断！"
	ngrok authtoken $authtoken
	"Ngrok Authtoken授权成功"
}

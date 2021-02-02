#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Ubuntu 18.04 初始安装配置，不要后期使用.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-f, --flag      Some flag description
-p, --param     Some param description
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # 写入清理代码，如删除临时文件#
}

if [[ $UID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

#####################################################################
# 系统优化
echo "配置sudo,inputrc,apport"
sed -i 's/^%sudo.*/%sudo    ALL=(ALL:ALL) NOPASSWD:ALL/g' /etc/sudoers
# 如果修改错误导致无法运行visudo，可以使用`pkexec visudo`
ignore_case="set completion-ignore-case on"
grep -Fxq "$ignore_case" /etc/inputrc || echo -e "$ignore_case" >> /etc/inputrc

sed -i 's/enabled=1/enabled=0/g' /etc/default/apport
# 设置时间采用本地时间
# sudo timedatectl set-local-rtc 1
#####################################################################
# 禁用systemd-resolved, 它经常将复杂网络配置搞坏。
systemctl disable systemd-resolved
systemctl stop systemd-resolved
rm /etc/resolv.conf  # 删除符号链接
echo "nameserver 114.114.114.114" |tee /etc/resolv.conf

#####################################################################
# NetworkManager DNS相关
# 桌面环境会使用networkmanager进行dns管理，所以还需要在
# /etc/NetworkManager/NetworkManager.conf中加入dns=none
NMconf=/etc/NetworkManager/NetworkManager.conf
sed -i 's/dns=.*/dns=none/g' "$NMconf" || sed -i '/main/ a dns=none' "$NMconf" 
#####################################################################
# apt/pip国内源并更新
echo "use https://developer.aliyun.com/mirror/"
cat > /etc/apt/sources.list << EOF
deb https://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
EOF
# cat > /etc/apt/sources.list << EOF
# deb https://mirrors.aliyun.com/ubuntu/ xenial main
# deb https://mirrors.aliyun.com/ubuntu/ xenial-updates main
# deb https://mirrors.aliyun.com/ubuntu/ xenial universe
# deb https://mirrors.aliyun.com/ubuntu/ xenial-updates universe
# deb https://mirrors.aliyun.com/ubuntu/ xenial-security main
# deb https://mirrors.aliyun.com/ubuntu/ xenial-security universe
# EOF
# cat > /etc/apt/apt.conf << EOF
# Acquire::http::Proxy "http://192.168.10.8:3142";
# EOF

cat > /etc/pip.conf << EOF
[global]
index-url = https://mirrors.aliyun.com/pypi/simple
EOF

#####################################################################
# 更新并删除不必要的程序
apt update ||exit 1
apt purge firefox thunderbird aisleriot gnome-mahjongg gnome-mines gnome-sudoku nano
apt autoremove
apt upgrade -y||exit 2
#####################################################################
# 输入法与语言
echo "在区域/语言设置中添加选择fcitx而不是xim/ibus."
apt install fcitx-table-wbpy fcitx-sunpinyin -y
## kernel <5.4 support exfat
apt install exfat-fuse exfat-utils -y
#####################################################################
# 必要软件
apt install chromium-browser openssh-server python3-pip python-pip -y
#####################################################################
# 代理
#sudo apt install shadowsocks-libev
#####################################################################

# user(推荐局域网使用同用户名，不同主机名）
# useradd -m -g users -G sudo/wheel -s /bin/sh username
# passwd username
# sudo usermod -l newUsername oldUsername
# sudo usermod -d /home/newHomeDir -m newUsername #不需要事先创建目录
# sudo groupmod oldUsername -n newUsername
# sudo chfn -f "newUsername" newUsername

# wireshark
# sudo apt install wireshark
# sudo dpkg-reconfigure wireshark-common 选择yes
# sudo gpasswd -a $USER wireshark
# reboot

## 添加自定义lua插件
# sudo apt install lua-sql-mysql lua-sql-mysql-dev
# sudo apt install mysql-server mysql-workbench
# cp custom.lua ~/.config/wireshark/plugins/

# 自动挂载硬盘
# 编辑 /etc/fstab
# 添加下面的行来挂载ssd:
# UUID=... /home/jec/data ext4 noatime,discard,user 0 2
# 权限只要用chown更改所有权即可

# 字体
# apt install ttf-mscorefonts-installer
# fc-cache -f -v

# 或者拷贝Windows的Fonts文件夹到/usr/share/fonts/下
# sudo apt install gnome-tweeks

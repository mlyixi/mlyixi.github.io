#! /bin/sh

#########################################################
## make linux as a gateway ##
#########################################################
# enable ip forward
sysctl net.ipv4.ip_forward = 1
# enable at boot
echo 'net.ipv4.ip_forward = 1' |sudo tee -a /etc/sysctl.conf
# enable nat: 
# LAN_in= enp0s20f0u1u1  WAN_OUT=wlp1s0
iptables -t nat -A POSTROUTING -o wlp1s0 -j MASQUERADE
iptables -A FORWARD -i enp0s20f0u1u1 -o wlp1s0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s20f0u1u1 -o wlp1s0 -j ACCEPT

#!/bin/bash

SSH_PORT="$1"
SWAP_SIZE="$2"

# install basic packages
apt update
apt install -y \
    ca-certificates \
    apt-transport-https \
    git \
    curl \
    wget \
    unzip \
    screen \
    net-tools \
    dnsutils \
    nano \
    gnupg2 \
    resolvconf

# use DEB822 format
rm -f /etc/apt/sources.list
cat > /etc/apt/sources.list.d/debian.sources << EOF
Types: deb
URIs: https://deb.debian.org/debian
Suites: trixie trixie-updates trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp

Types: deb
URIs: https://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp
EOF
apt update
apt upgrade -y

# setup swap
fallocate -l $SWAP_SIZE /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
cat <<EOF >> /etc/fstab
/swapfile none swap sw 0 0
EOF
mount -a

# setup ntp
apt update
apt install -y chrony
systemctl enable chrony
systemctl restart chrony

# setup ssh
sed -i 's/^#\?PermitRootLogin.*$/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication.*$/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*$/PasswordAuthentication no/g' /etc/ssh/sshd_config
systemctl restart sshd

# setup fail2ban
apt update
apt install -y fail2ban
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime  = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled = true
port    = $SSH_PORT
logpath = /var/log/auth.log 
EOF
systemctl enable fail2ban
systemctl restart fail2ban

# setup ufw
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
sed -i 's/IPV6=no/IPV6=yes/' /etc/default/ufw
ufw allow $SSH_PORT/tcp
ufw enable

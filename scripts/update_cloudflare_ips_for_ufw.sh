#!/bin/bash

# check root
if [[ $EUID -ne 0 ]]; then
   exit 1
fi

# Cloudflare IPs URL
CF_IPV4_URL="https://www.cloudflare.com/ips-v4"
CF_IPV6_URL="https://www.cloudflare.com/ips-v6"

# remove exist rules
CF_RULES=$(ufw status numbered | grep '# Cloudflare' | grep -oP '\[\s*\K\d+(?=\])' | sort -rn)
if [ -z "$CF_RULES" ]; then
    echo "no rule should be deleted"
else
    for NUM in $CF_RULES; do
        ufw --force delete $NUM
    done
fi

# add rules for IPv4
while read ip; do
    if [[ ! -z "$ip" ]]; then
        ufw allow proto tcp from $ip to any port 80 comment 'Cloudflare IPv4 HTTP'
        ufw allow proto tcp from $ip to any port 443 comment 'Cloudflare IPv4 HTTPS'
    fi
done < <(curl -sL "$CF_IPV4_URL")

# add rules for IPv6
while read ip; do
    if [[ ! -z "$ip" ]]; then
        ufw allow proto tcp from $ip to any port 80 comment 'Cloudflare IPv6 HTTP'
        ufw allow proto tcp from $ip to any port 443 comment 'Cloudflare IPv6 HTTPS'
    fi
done < <(curl -sL "$CF_IPV6_URL")

# print latest rules
ufw status numbered

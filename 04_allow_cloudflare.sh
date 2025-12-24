#!/bin/bash

# download scripts
curl -fLO https://raw.githubusercontent.com/kotoyuuko/debian-server-init/refs/heads/main/scripts/update_cloudflare_ips_for_ufw.sh
curl -fLO https://raw.githubusercontent.com/kotoyuuko/debian-server-init/refs/heads/main/scripts/update_cloudflare_ips_for_nginx.sh

# move scripts
mkdir -p /scripts/cloudflare
mv update_cloudflare_ips_for_ufw.sh /scripts/cloudflare/
mv update_cloudflare_ips_for_nginx.sh /scripts/cloudflare/
chmod +x /scripts/cloudflare/update_cloudflare_ips_for_ufw.sh
chmod +x /scripts/cloudflare/update_cloudflare_ips_for_nginx.sh /etc/nginx/cloudflare/real_ip.conf

# run scripts
bash /scripts/cloudflare/update_cloudflare_ips_for_ufw.sh
bash /scripts/cloudflare/update_cloudflare_ips_for_nginx.sh

# tasks
UFW_JOB="0 3 * * * /scripts/cloudflare/update_cloudflare_ips_for_ufw.sh > /dev/null 2>&1"
NGINX_JOB="10 3 * * * /scripts/cloudflare/update_cloudflare_ips_for_nginx.sh /etc/nginx/cloudflare/real_ip.conf > /dev/null 2>&1"

# add crontab
(crontab -l 2>/dev/null | grep -Fq "$UFW_JOB") || (crontab -l 2>/dev/null; echo "$UFW_JOB") | crontab -
(crontab -l 2>/dev/null | grep -Fq "$NGINX_JOB") || (crontab -l 2>/dev/null; echo "$NGINX_JOB") | crontab -

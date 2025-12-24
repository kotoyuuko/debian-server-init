#!/bin/bash

CERT_DOMAIN="$1"

# install the prerequisites
apt install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring

# import gpg key
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    
# verify gpg key
mkdir -m 700 ~/.gnupg
gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/debian `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list

# install nginx
apt update
apt install -y nginx

# start nginx
systemctl start nginx
systemctl enable nginx

# generate self signed cert
mkdir -p /etc/nginx/certs/self
openssl genrsa -out /etc/nginx/certs/self/privkey.pem 2048
openssl req -new -x509 -days 3650 -key /etc/nginx/certs/self/privkey.pem \
    -out /etc/nginx/certs/self/cert.pem \
    -subj "/C=CN/O=Self Hosted/OU=SRE/CN=$DOMAIN/CN=*.$DOMAIN"

# default vhost
rm -f /etc/nginx/conf.d/default.conf
cat > /etc/nginx/conf.d/00-default.conf << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 418;
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    server_name _;
    ssl_certificate /etc/nginx/certs/self/cert.pem;
    ssl_certificate_key /etc/nginx/certs/self/privkey.pem;
    return 418;
}
EOF
nginx -t
systemctl force-reload nginx

#!/bin/bash

# nginx.conf
cat > /etc/nginx/nginx.conf <<EOF
user www-data www-data;
worker_processes auto;
worker_cpu_affinity auto;
worker_rlimit_nofile 51200;
pid /run/nginx.pid;

error_log /var/log/nginx/error.log crit;

events {
  use epoll;
  worker_connections 51200;
  multi_accept off;
  accept_mutex off;
}

http {
  include mime.types;
  default_type application/octet-stream;

  log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

  server_names_hash_bucket_size 128;
  client_header_buffer_size 32k;
  large_client_header_buffers 4 32k;
  client_max_body_size 64m;

  sendfile on;
  sendfile_max_chunk 512k;
  tcp_nopush on;

  keepalive_timeout 60;

  tcp_nodelay on;

  fastcgi_connect_timeout 300;
  fastcgi_send_timeout 300;
  fastcgi_read_timeout 300;
  fastcgi_buffer_size 64k;
  fastcgi_buffers 4 64k;
  fastcgi_busy_buffers_size 128k;
  fastcgi_temp_file_write_size 256k;

  gzip on;
  gzip_min_length 1k;
  gzip_buffers 4 16k;
  gzip_http_version 1.1;
  gzip_comp_level 2;
  gzip_types text/plain application/javascript application/x-javascript text/javascript text/css application/xml application/xml+rss;
  gzip_vary on;
  gzip_proxied expired no-cache no-store private auth;
  gzip_disable "MSIE [1-6]\.";

  server_tokens off;
  access_log off;

  include cloudflare/real_ip.conf;
  include conf.d/*.conf;
}
EOF

# create snippets dir
mkdir -p /etc/nginx/snippets
mkdir -p /etc/nginx/cloudflare

# cloudflare/real_ip.conf
touch /etc/nginx/cloudflare/real_ip.conf

# cloudflare/enable-cdn.conf
cat > /etc/nginx/cloudflare/enable-cdn.conf <<EOF
ssl_prefer_server_ciphers off;
ssl_session_timeout 1d;
ssl_session_cache shared:MozSSL:10m;
EOF

# snippets/enable-ssl.conf
cat > /etc/nginx/snippets/enable-ssl.conf <<EOF
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ecdh_curve X25519:P-256:P-384;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-CHACHA20-POLY1305:ECDHE+AES128:RSA+AES128:ECDHE+AES256:RSA+AES256';
EOF

# snippets/enable-hsts.conf
cat > /etc/nginx/snippets/enable-hsts.conf <<EOF
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
EOF

# reload nginx
systemctl force-reload nginx

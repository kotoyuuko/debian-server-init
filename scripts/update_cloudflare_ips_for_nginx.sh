#!/bin/bash

# output file
OUTPUT_FILE="$1"
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"

# check root
if [[ $EUID -ne 0 ]]; then
   exit 1
fi

# Cloudflare IPs URL
CF_IPV4_URL="https://www.cloudflare.com/ips-v4"
CF_IPV6_URL="https://www.cloudflare.com/ips-v6"

# write file header
cat <<EOF > $OUTPUT_FILE
# Cloudflare Real IP Configuration
# Generated at: $(date)
EOF

# write IPv4 header
cat <<EOF >> $OUTPUT_FILE

# IPv4: $CF_IPV4_URL
EOF

# fetch & process IPv4
curl -sL $CF_IPV4_URL | sed 's|^|set_real_ip_from |; s|$|;|' >> $OUTPUT_FILE

# write IPv6 header
cat <<EOF >> $OUTPUT_FILE

# IPv6: $CF_IPV6_URL
EOF

# fetch & process IPv6
curl -sL $CF_IPV6_URL | sed 's|^|set_real_ip_from |; s|$|;|' >> $OUTPUT_FILE

# write file footer
cat <<EOF >> $OUTPUT_FILE

# Using CF-Connecting-IP to fetch real ip
real_ip_header CF-Connecting-IP;
EOF

# reload nginx
systemctl force-reload nginx

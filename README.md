# Debian Server Init

---

## Reinstall Debian

```shell
curl -fLO https://raw.githubusercontent.com/bohanyang/debi/master/debi.sh
chmod +x debi.sh
./debi.sh \
    --version 13 \
    --architecture amd64 \
    --cloudflare \
    --user username \
    --authorized-keys-url https://github.com/username.keys \
    --ssh-port 22 \
    --bbr
reboot
```

## Init New Server

```shell
apt update
apt install -y git
git clone https://github.com/kotoyuuko/debian-server-init
cd debian-server-init
chmod +x *.sh
./01_server_init.sh 22 8G
./02_install_nginx.sh your-domain.com
./03_install_docker.sh
./04_allow_cloudflare.sh
```

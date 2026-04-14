# === nginx ===
sudo su -
systemctl stop nginx
apt purge nginx nginx-common nginx-full libnginx-mod-* -y
rm -rf /etc/nginx
rm -rf /var/log/nginx
rm -rf /var/www/html
apt autoremove -y

# === DOCKER ===
sudo su -
systemctl stop docker docker.socket containerd
apt purge docker-ce docker-ce-cli docker-compose-plugin containerd.io -y
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
rm -rf /etc/docker
rm -rf /root/.docker
apt autoremove -y

# === PODMAN ===
sudo su -
systemctl stop podman podman.socket
apt purge podman buildah skopeo -y
rm -rf /var/lib/containers
rm -rf /etc/containers
rm -rf /root/.local/share/containers
apt autoremove -y
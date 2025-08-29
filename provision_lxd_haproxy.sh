#!/usr/bin/env bash
set -euo pipefail

echo "[Base] Paquetes base y snapd..."
sudo apt-get update -y
sudo apt-get install -y snapd curl

echo "[LXD] Instalando e inicializando LXD..."
sudo snap install lxd
sudo /snap/bin/lxd waitready
# Init no interactivo con bridge por defecto (lxdbr0)
sudo /snap/bin/lxd init --auto

echo "[LXD] Lanzando contenedores web1 y web2 (Ubuntu 22.04)..."
for n in web1 web2; do
  if ! sudo /snap/bin/lxc info "$n" >/dev/null 2>&1; then
    sudo /snap/bin/lxc launch images:ubuntu/22.04 "$n"
  fi
done

echo "[LXD] Instalando Nginx y páginas personalizadas en cada contenedor..."
for n in web1 web2; do
  sudo /snap/bin/lxc exec "$n" -- bash -lc 'apt-get update -y && apt-get install -y nginx && systemctl enable --now nginx'
done

sudo /snap/bin/lxc exec web1 -- bash -lc "cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html><html lang=\"es\"><meta charset=\"utf-8\"><title>web1</title>
<body style=\"font-family:sans-serif\">
<h1>Hola desde web1 (LXD)</h1><p>Servido por Nginx dentro del contenedor <b>web1</b>.</p>
</body></html>
EOF"

sudo /snap/bin/lxc exec web2 -- bash -lc "cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html><html lang=\"es\"><meta charset=\"utf-8\"><title>web2</title>
<body style=\"font-family:sans-serif\">
<h1>Hola desde web2 (LXD)</h1><p>Servido por Nginx dentro del contenedor <b>web2</b>.</p>
</body></html>
EOF"

echo "[IPs] Obteniendo IPs de los contenedores..."
WEB1_IP=$(sudo /snap/bin/lxc exec web1 -- bash -lc "hostname -I | awk '{print \$1}'")
WEB2_IP=$(sudo /snap/bin/lxc exec web2 -- bash -lc "hostname -I | awk '{print \$1}'")
echo "web1: $WEB1_IP"
echo "web2: $WEB2_IP"

echo "[HAProxy] Instalando y configurando balanceador en la VM..."
sudo apt-get install -y haproxy
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak

sudo tee /etc/haproxy/haproxy.cfg >/dev/null <<EOF
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon

defaults
    mode http
    log global
    option httplog
    option dontlognull
    timeout connect 5s
    timeout client  50s
    timeout server  50s

frontend http-in
    bind *:80
    default_backend web-backend

backend web-backend
    balance roundrobin
    server web1 ${WEB1_IP}:80 check
    server web2 ${WEB2_IP}:80 check
EOF

echo "[HAProxy] Habilitando servicio..."
sudo systemctl enable --now haproxy

echo "[Test] Probando en la VM..."
curl -s http://127.0.0.1 | head -n 5 || true

echo "[DONE] LXD + HAProxy listo."

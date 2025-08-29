#!/usr/bin/env bash
set -e

# Install Consul y HAProxy
sudo apt-get install -y consul haproxy

# Configuracion Consul servidor
sudo mkdir -p /etc/consul.d
sudo tee /etc/consul.d/server.hcl > /dev/null <<'HCL'
datacenter = "dc1"
node_name  = "lb"
server     = true
bootstrap_expect = 1
data_dir   = "/var/lib/consul"
bind_addr  = "0.0.0.0"
client_addr = "0.0.0.0"
ui_config  { enabled = true }
enable_script_checks = true
HCL

# Systemd service
if [ ! -f /etc/systemd/system/consul.service ]; then
  sudo tee /etc/systemd/system/consul.service > /dev/null <<'UNIT'
[Unit]
Description=Consul Agent
Requires=network-online.target
After=network-online.target
[Service]
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
Restart=on-failure
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
UNIT
  sudo systemctl daemon-reload
fi

sudo systemctl enable consul
sudo systemctl restart consul

# Configuracion HAProxy (placeholder backend)
sudo tee /etc/haproxy/haproxy.cfg > /dev/null <<'CFG'
global
    daemon
    maxconn 2048
defaults
    mode http
    timeout connect 5s
    timeout client  30s
    timeout server  30s

frontend http_front
    bind *:8080
    default_backend web_pool

backend web_pool
    balance roundrobin
    # Estos servidores se actualizaron cuando registremos los servicios en Consul
    # (temporalmente apuntamos a web1 y web2)
    server web1 192.168.100.11:3000 check
    server web2 192.168.100.12:3000 check

listen stats
    bind *:8404
    mode http
    stats enable
    stats hide-version
    stats uri /stats
    stats refresh 5s
CFG

sudo systemctl enable haproxy
sudo systemctl restart haproxy
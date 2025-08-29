#!/usr/bin/env bash
set -e

# Install Consul y Node
sudo apt-get install -y consul
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# App Node.js simple
sudo mkdir -p /opt/nodeapp
sudo tee /opt/nodeapp/server.js > /dev/null <<'JS'
const http = require('http');
const port = process.env.PORT || 3000;
const hostname = '0.0.0.0';
const name = process.env.SVC_NAME || 'web';

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, {'Content-Type': 'application/json'});
    res.end(JSON.stringify({status:'ok', service:name}));
  } else {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end(`Hola desde ${name} en ${hostname}:${port}\n`);
  }
});

server.listen(port, hostname, () => {
  console.log(`Server ${name} escuchando en ${hostname}:${port}`);
});
JS

sudo tee /etc/systemd/system/nodeapp.service > /dev/null <<'UNIT'
[Unit]
Description=Node Web App
After=network.target
[Service]
Environment=PORT=3000
Environment=SVC_NAME=web
ExecStart=/usr/bin/node /opt/nodeapp/server.js
Restart=always
User=root
[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable nodeapp
sudo systemctl restart nodeapp

# Configuracion Consul (cliente)
IP=$(hostname -I | awk '{print $1}')
HOST=$(hostname)

sudo mkdir -p /etc/consul.d
sudo tee /etc/consul.d/client.hcl > /dev/null <<HCL
datacenter = "dc1"
node_name  = "${HOST}"
server     = false
data_dir   = "/var/lib/consul"
bind_addr  = "0.0.0.0"
client_addr= "0.0.0.0"
retry_join = ["192.168.100.10"]
enable_script_checks = true
HCL

# Definicion del servicio registrado en Consul
sudo tee /etc/consul.d/web.json > /dev/null <<'JSON'
{
  "service": {
    "name": "web",
    "port": 3000,
    "checks": [
      {
        "http": "http://127.0.0.1:3000/health",
        "interval": "5s",
        "timeout": "2s"
      }
    ]
  }
}
JSON

# Systemd service para Consul si no existe
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
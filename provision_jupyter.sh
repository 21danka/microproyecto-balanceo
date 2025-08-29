

set -e
echo "[Jupyter] Instalando dependencias..."
sudo apt-get update -y
sudo apt-get install -y python3-venv python3-pip

echo "[Jupyter] Creando venv en /opt/jupyter..."
sudo mkdir -p /opt/jupyter
sudo python3 -m venv /opt/jupyter
sudo /opt/jupyter/bin/pip install --upgrade pip
sudo /opt/jupyter/bin/pip install notebook

echo "[Jupyter] Creando servicio systemd..."
sudo tee /etc/systemd/system/jupyter.service >/dev/null <<'EOF'
[Unit]
Description=Jupyter Notebook (Vagrant)
After=network.target

[Service]
Type=simple
User=vagrant
Group=vagrant
WorkingDirectory=/home/vagrant
Environment=PATH=/opt/jupyter/bin:/usr/bin:/bin
ExecStart=/opt/jupyter/bin/jupyter notebook --ip=0.0.0.0 --no-browser --NotebookApp.token=
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "[Jupyter] Ajustando permisos del venv..."
sudo chown -R vagrant:vagrant /opt/jupyter

echo "[Jupyter] Habilitando y arrancando servicio..."
sudo systemctl daemon-reload
sudo systemctl enable --now jupyter

echo "[Jupyter] Listo."
sudo systemctl --no-pager --full status jupyter | sed -n '1,20p'

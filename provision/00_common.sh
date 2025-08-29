#!/usr/bin/env bash
set -e
sudo apt-get update -y
sudo apt-get install -y curl gnupg apt-transport-https ca-certificates lsb-release

# Repo HashiCorp (Consul)
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
sudo apt-get update -y
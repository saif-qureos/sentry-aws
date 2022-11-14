#!/bin/bash
set -ex

# Installing necessary dependencies
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
sudo apt-get update
sudo apt-get -y -qq install curl wget git vim apt-transport-https ca-certificates software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository  "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get -y install docker-ce
sudo usermod -aG docker ${USER}
sudo curl -L https://github.com/docker/compose/releases/download/1.28.5/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Setup sudo to allow no-password sudo for "thedomain" group and adding "theuser" user
sudo groupadd -r thedomain
sudo useradd -m -s /bin/bash theuser
sudo usermod -aG thedomain theuser
sudo usermod -aG docker theuser
sudo cp /etc/sudoers /etc/sudoers.orig
echo "theuser  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/thedomain

# Installing SSH key
sudo mkdir -p /home/theuser/.ssh
sudo chmod 700 /home/theuser/.ssh
sudo cp /tmp/the-keys.pub /home/theuser/.ssh/authorized_keys
sudo chmod 600 /home/theuser/.ssh/authorized_keys
sudo chown -R theuser /home/theuser/.ssh
sudo usermod --shell /bin/bash theuser
sudo usermod -aG sudo theuser 
sudo chown -R theuser /home/theuser/

# Preparing Sentry
sudo -H -i -u theuser -- env bash << EOF
whoami
echo ~theuser
cd /home/theuser
wget https://github.com/getsentry/onpremise/archive/refs/tags/21.3.0.tar.gz
tar -zxvf 21.3.0.tar.gz
cd self-hosted-21.3.0/
sudo ./install.sh --no-user-prompt
EOF
echo "end of sentry bootstrapping"

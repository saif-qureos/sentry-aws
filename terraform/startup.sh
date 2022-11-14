#!/bin/bash
sudo -H -i -u theuser -- env bash << EOF
whoami
echo ~theuser
cd /home/theuser/self-hosted-21.3.0
sudo docker-compose up -d
EOF

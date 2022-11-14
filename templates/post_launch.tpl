#!/bin/bash
sudo -H -i -u theuser -- env bash <<EOF
whoami
echo ~theuser
cd /home/theuser/self-hosted-21.3.0/sentry
sudo sed -i 's/"NAME": "postgres"/"NAME": "${db_name}"/g' sentry.conf.py
sudo sed -i 's/"USER": "postgres"/"USER": "${db_user}"/g' sentry.conf.py
sudo sed -i 's/"PASSWORD": ""/"PASSWORD": "${db_password}"/g' sentry.conf.py
sudo sed -i 's/"PORT": ""/"PORT": "${port}"/g' sentry.conf.py
sudo sed -i 's/"HOST": "postgres"/"HOST": "${endpoint}"/g' sentry.conf.py
cd ..
sudo ./install.sh --no-user-prompt
EOF
#!/bin/bash
set -e

# Wait for cloud-init
sleep 10

apt-get update

# Install K6
gpg -k
gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo 'deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main' | tee /etc/apt/sources.list.d/k6.list
apt-get update
apt-get install -y k6

# Install Python and Locust
apt-get install -y python3 python3-pip
pip3 install locust

# Install Apache Bench
apt-get install -y apache2-utils

# Create directories
mkdir -p /home/ubuntu/{k6-scripts,locust-scripts,results}
chown -R ubuntu:ubuntu /home/ubuntu/{k6-scripts,locust-scripts,results}

echo 'Load test server setup complete' > /home/ubuntu/setup-complete.txt

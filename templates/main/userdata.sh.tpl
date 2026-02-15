#!/bin/bash
set -e

# Wait for cloud-init
sleep 10

# Install Docker
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
usermod -aG docker ubuntu
systemctl enable docker && systemctl start docker

# Install Alloy for metrics/logs/traces collection
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main' | tee /etc/apt/sources.list.d/grafana.list
apt-get update
apt-get install -y alloy

# Add alloy user to docker group for log collection
usermod -aG docker alloy

# Create directories
mkdir -p /home/ubuntu/{app,configs}
chown -R ubuntu:ubuntu /home/ubuntu/{app,configs}

# Write config files
cat > /home/ubuntu/app/docker-compose.yml << 'COMPOSEEOF'
${compose_content}
COMPOSEEOF

cat > /etc/alloy/config.alloy << 'ALLOYEOF'
${alloy_config}
ALLOYEOF

# Start Redis
cd /home/ubuntu/app
docker compose up -d

# Restart Alloy with new config
systemctl restart alloy

echo 'Main server setup complete' > /home/ubuntu/setup-complete.txt

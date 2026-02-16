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

# Create directories
mkdir -p /home/ubuntu/app
chown -R ubuntu:ubuntu /home/ubuntu/app

# Write config files
cat > /home/ubuntu/app/docker-compose.yml << 'COMPOSEEOF'
${compose_content}
COMPOSEEOF

cat > /home/ubuntu/app/alloy-config.alloy << 'ALLOYEOF'
${alloy_config}
ALLOYEOF

# Start all services
cd /home/ubuntu/app
docker compose up -d

echo 'Main server setup complete' > /home/ubuntu/setup-complete.txt

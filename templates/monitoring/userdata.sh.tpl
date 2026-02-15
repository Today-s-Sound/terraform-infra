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
mkdir -p /home/ubuntu/monitoring/{prometheus,grafana/provisioning/datasources,loki,tempo}
chown -R ubuntu:ubuntu /home/ubuntu/monitoring

# Write config files
cat > /home/ubuntu/monitoring/docker-compose.yml << 'COMPOSEEOF'
${compose_content}
COMPOSEEOF

cat > /home/ubuntu/monitoring/prometheus/prometheus.yml << 'PROMEOF'
${prometheus_config}
PROMEOF

cat > /home/ubuntu/monitoring/loki/loki-config.yml << 'LOKIEOF'
${loki_config}
LOKIEOF

cat > /home/ubuntu/monitoring/tempo/tempo-config.yml << 'TEMPOEOF'
${tempo_config}
TEMPOEOF

cat > /home/ubuntu/monitoring/grafana/provisioning/datasources/datasources.yml << 'GRAFANAEOF'
${grafana_datasources}
GRAFANAEOF

# Start monitoring stack
cd /home/ubuntu/monitoring
docker compose up -d

echo 'Monitoring server setup complete' > /home/ubuntu/setup-complete.txt

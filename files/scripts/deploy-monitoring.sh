#!/bin/bash
# Deploy monitoring stack (Prometheus + Grafana + Loki + Alloy)

set -e

MONITORING_DIR="$HOME/docker/monitoring"
CONFIG_DIR="$HOME/configs"

echo "Deploying monitoring stack..."

# Create directory
mkdir -p "$MONITORING_DIR"

# Copy all config files
echo "Copying configuration files..."
cp "$CONFIG_DIR/prometheus/prometheus.yml" "$MONITORING_DIR/"
cp "$CONFIG_DIR/loki/loki-config.yaml" "$MONITORING_DIR/"
cp "$CONFIG_DIR/alloy/config.alloy" "$MONITORING_DIR/"
cp "$CONFIG_DIR/grafana/datasources.yml" "$MONITORING_DIR/"

# Deploy with Docker Compose
echo "Starting services..."
cd "$MONITORING_DIR"
docker compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10

echo ""
echo "✅ Monitoring stack deployed successfully!"
echo ""
echo "📊 Service URLs:"
echo "  - Grafana:    http://$(curl -s ifconfig.me):3000 (admin/admin)"
echo "  - Prometheus: http://$(curl -s ifconfig.me):9090"
echo "  - Loki:       http://$(curl -s ifconfig.me):3100"
echo "  - Alloy:      http://$(curl -s ifconfig.me):12345"
echo ""
echo "📝 Logs: docker compose logs -f"
echo "🔄 Restart: docker compose restart"
echo "🛑 Stop: docker compose down"

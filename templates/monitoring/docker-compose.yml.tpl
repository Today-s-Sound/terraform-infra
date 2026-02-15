services:
  prometheus:
    image: prom/prometheus:latest
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=15d'
      - '--web.enable-remote-write-receiver'

  grafana:
    image: grafana/grafana:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin

  loki:
    image: grafana/loki:latest
    restart: unless-stopped
    ports:
      - "3100:3100"
    volumes:
      - ./loki/loki-config.yml:/etc/loki/local-config.yaml
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml

  tempo:
    image: grafana/tempo:latest
    restart: unless-stopped
    ports:
      - "3200:3200"
      - "4317:4317"
      - "4318:4318"
    volumes:
      - ./tempo/tempo-config.yml:/etc/tempo/tempo.yaml
      - tempo-data:/var/tempo
    command: -config.file=/etc/tempo/tempo.yaml

  mysqld-exporter:
    image: prom/mysqld-exporter:latest
    restart: unless-stopped
    ports:
      - "9104:9104"
    environment:
      - DATA_SOURCE_NAME=${db_username}:${db_password}@tcp(${rds_address}:3306)/${db_name}

volumes:
  prometheus-data:
  grafana-data:
  loki-data:
  tempo-data:

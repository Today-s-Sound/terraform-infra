// ===== Metrics: Scrape Spring Boot & forward to Prometheus =====
prometheus.remote_write "monitoring" {
  endpoint {
    url = "http://${monitoring_private_ip}:9090/api/v1/write"
  }
}

prometheus.scrape "spring_boot" {
  targets    = [{"__address__" = "localhost:8080"}]
  metrics_path = "/actuator/prometheus"
  scrape_interval = "15s"
  forward_to = [prometheus.remote_write.monitoring.receiver]
}

// ===== Logs: Collect Docker logs & forward to Loki =====
discovery.docker "containers" {
  host = "unix:///var/run/docker.sock"
}

loki.source.docker "containers" {
  host       = "unix:///var/run/docker.sock"
  targets    = discovery.docker.containers.targets
  forward_to = [loki.write.monitoring.receiver]
}

loki.write "monitoring" {
  endpoint {
    url = "http://${monitoring_private_ip}:3100/loki/api/v1/push"
  }
}

// ===== Traces: Receive OTLP from Spring Boot & forward to Tempo =====
otelcol.receiver.otlp "default" {
  grpc {
    endpoint = "0.0.0.0:4317"
  }
  http {
    endpoint = "0.0.0.0:4318"
  }
  output {
    traces = [otelcol.exporter.otlp.tempo.input]
  }
}

otelcol.exporter.otlp "tempo" {
  client {
    endpoint = "${monitoring_private_ip}:4317"
    tls {
      insecure = true
    }
  }
}

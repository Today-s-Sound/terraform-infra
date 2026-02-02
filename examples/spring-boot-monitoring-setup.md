# Spring Boot 모니터링 설정 가이드

Main Server에서 Spring Boot 애플리케이션의 메트릭과 로그를 Monitoring Server로 전송하는 방법입니다.

## 아키텍처

```
Main Server                    Monitoring Server
┌──────────────────┐          ┌──────────────────┐
│ Spring Boot      │          │ Prometheus       │
│ /actuator/metrics│          │                  │
│        ↓         │          │                  │
│ Alloy Agent      │─────────→│ Grafana          │
│  (수집/전송)     │ metrics  │                  │
│                  │          │                  │
│ Docker Logs      │          │ Loki             │
│        ↓         │          │                  │
│ Alloy Agent      │─────────→│                  │
│                  │  logs    │                  │
└──────────────────┘          └──────────────────┘
```

## 1. Spring Boot 설정

### build.gradle에 의존성 추가

```gradle
dependencies {
    // Spring Boot Actuator
    implementation 'org.springframework.boot:spring-boot-starter-actuator'

    // Prometheus metrics
    implementation 'io.micrometer:micrometer-registry-prometheus'

    // 기타 의존성...
}
```

### application.yml 설정

```yaml
spring:
  application:
    name: todays-sound-backend

management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus,metrics
      base-path: /actuator

  endpoint:
    health:
      show-details: always
    prometheus:
      enabled: true

  metrics:
    export:
      prometheus:
        enabled: true
    tags:
      application: ${spring.application.name}
      environment: ${SPRING_PROFILES_ACTIVE:dev}

  # Optional: Custom metrics
  health:
    redis:
      enabled: true
```

### 커스텀 메트릭 추가 (선택사항)

```java
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Service;

@Service
public class MyService {
    private final Counter requestCounter;

    public MyService(MeterRegistry meterRegistry) {
        this.requestCounter = meterRegistry.counter("custom.requests",
            "endpoint", "api");
    }

    public void handleRequest() {
        requestCounter.increment();
        // 비즈니스 로직...
    }
}
```

## 2. Docker Compose 설정

Main Server의 `docker-compose.yml`:

```yaml
services:
  spring-app:
    image: your-app:latest
    environment:
      - MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,prometheus
      - MANAGEMENT_METRICS_EXPORT_PROMETHEUS_ENABLED=true
    labels:
      - "prometheus.scrape=true"
      - "prometheus.port=8080"
      - "prometheus.path=/actuator/prometheus"

  redis:
    image: redis:7-alpine

  alloy:
    image: grafana/alloy:latest
    volumes:
      - ./alloy-config.alloy:/etc/alloy/config.alloy
      - /var/run/docker.sock:/var/run/docker.sock:ro
```

## 3. Alloy 설정

`alloy-config.alloy`:

```hcl
// Monitoring Server IP를 실제 IP로 변경!
prometheus.remote_write "monitoring" {
  endpoint {
    url = "http://MONITORING_SERVER_IP:9090/api/v1/write"
  }
}

loki.write "monitoring" {
  endpoint {
    url = "http://MONITORING_SERVER_IP:3100/loki/api/v1/push"
  }
}

// Spring Boot 메트릭 수집
prometheus.scrape "spring_boot" {
  targets = [{
    __address__ = "spring-app:8080",
    __metrics_path__ = "/actuator/prometheus",
  }]
  forward_to = [prometheus.remote_write.monitoring.receiver]
}

// Docker 로그 수집
loki.source.docker "containers" {
  host = "unix:///var/run/docker.sock"
  forward_to = [loki.write.monitoring.receiver]
}
```

## 4. 배포 순서

```bash
# 1. Monitoring Server 먼저 시작 (terraform-infra 레포)
cd terraform-infra
terraform apply  # Monitoring Server 생성
# Monitoring Server IP 확인: terraform output monitoring_server_ip

# 2. alloy-config.alloy에 Monitoring Server IP 설정
vim alloy-config.alloy
# MONITORING_SERVER_IP를 실제 IP로 변경

# 3. Spring Boot 배포 (backend 레포)
cd ../backend
git push  # CI/CD가 자동 배포
```

## 5. 확인

### Spring Boot 메트릭 확인
```bash
# Main Server에서 직접 확인
curl http://localhost:8080/actuator/prometheus

# 출력 예시:
# jvm_memory_used_bytes{area="heap"} 123456789
# http_server_requests_seconds_count{method="GET",uri="/api/users"} 42
```

### Grafana에서 확인

1. Grafana 접속: `http://MONITORING_SERVER_IP:3000`
2. Explore → Prometheus 선택
3. 쿼리 예시:
   ```promql
   # HTTP 요청 수
   rate(http_server_requests_seconds_count[5m])

   # JVM 메모리 사용량
   jvm_memory_used_bytes{application="todays-sound-backend"}

   # Redis 연결 수
   redis_connections_current
   ```

4. Explore → Loki 선택
5. 로그 쿼리 예시:
   ```logql
   # Spring Boot 로그
   {container="spring-app"}

   # 에러 로그만
   {container="spring-app"} |= "ERROR"

   # 특정 API 로그
   {container="spring-app"} |= "/api/users"
   ```

## 6. Grafana 대시보드 추천

### JVM Dashboard (ID: 4701)
```bash
# Grafana → Dashboards → Import → 4701
```

### Spring Boot Dashboard (ID: 12900)
```bash
# Grafana → Dashboards → Import → 12900
```

### Custom Dashboard 예시
```json
{
  "title": "Todays Sound Backend",
  "panels": [
    {
      "title": "Request Rate",
      "targets": [
        {
          "expr": "rate(http_server_requests_seconds_count{application=\"todays-sound-backend\"}[5m])"
        }
      ]
    },
    {
      "title": "JVM Memory",
      "targets": [
        {
          "expr": "jvm_memory_used_bytes{application=\"todays-sound-backend\",area=\"heap\"}"
        }
      ]
    }
  ]
}
```

## 7. 알림 설정 (Optional)

Grafana Alert 예시:

```yaml
# High Memory Usage Alert
- alert: HighMemoryUsage
  expr: |
    (jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"}) > 0.9
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "JVM heap memory usage is above 90%"
    description: "Application {{ $labels.application }} heap usage: {{ $value }}"
```

## 8. 트러블슈팅

### 메트릭이 안 보일 때
```bash
# 1. Spring Boot Actuator 확인
curl http://localhost:8080/actuator/prometheus

# 2. Alloy Agent 로그 확인
docker logs alloy-agent

# 3. Prometheus target 확인
# Monitoring Server에서: http://MONITORING_SERVER_IP:9090/targets
```

### 로그가 안 보일 때
```bash
# 1. Docker 로그 확인
docker logs spring-app

# 2. Alloy Agent 로그 확인
docker logs alloy-agent

# 3. Loki에서 확인
# Grafana → Explore → Loki → {container="spring-app"}
```

## 9. 성능 고려사항

### Metrics Cardinality
- 너무 많은 label 사용 주의
- 동적 label 값 피하기 (user_id 등)
- Micrometer `@Timed` 적절히 사용

### Log Volume
- 로그 레벨 적절히 설정 (DEBUG → INFO)
- 불필요한 로그 제거
- Loki retention 설정 (현재 31일)

### Resource Usage
- Alloy Agent: ~50-100MB RAM
- 메트릭 전송: ~1-5MB/min
- 로그 전송: 애플리케이션 로그량에 따라

## 요약

```
✅ Spring Boot에 actuator + prometheus 의존성 추가
✅ docker-compose.yml에 alloy 컨테이너 추가
✅ alloy-config.alloy에서 Monitoring Server IP 설정
✅ Grafana에서 대시보드 생성
✅ 완료!
```

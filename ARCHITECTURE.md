# 인프라 아키텍처

## 3-Tier Server Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        GCP Project                          │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    VPC Network                        │  │
│  │                 Subnet: 10.0.10.0/24                 │  │
│  │                                                       │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │  │
│  │  │ Main Server  │  │ Monitoring   │  │ Load Test  │ │  │
│  │  │              │  │   Server     │  │   Server   │ │  │
│  │  ├──────────────┤  ├──────────────┤  ├────────────┤ │  │
│  │  │ Application  │  │ Prometheus   │  │ K6         │ │  │
│  │  │ Redis        │  │ Grafana      │  │ Locust     │ │  │
│  │  │ Alloy Agent  │  │ Loki         │  │ Apache AB  │ │  │
│  │  │              │  │ Alloy        │  │            │ │  │
│  │  └──────┬───────┘  └──────┬───────┘  └─────┬──────┘ │  │
│  │         │                 │                 │        │  │
│  │         └─────────────────┴─────────────────┘        │  │
│  │              Metrics & Logs Flow                     │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Server Roles

### 1. Main Server (e2-medium)
**Purpose**: Primary application server with Redis cache

**Components**:
- Application (Docker container)
- Redis (Docker container)
- Alloy Agent (system package) - sends logs/metrics to monitoring server

**Ports**:
- 8080: Application
- 6379: Redis (internal only)

**Resources**:
- 2 vCPU, 4GB RAM
- 30GB disk

### 2. Monitoring Server (e2-small)
**Purpose**: Centralized observability stack

**Components**:
- Prometheus: Metrics storage
- Grafana: Visualization
- Loki: Log aggregation
- Alloy: Telemetry collector

**Ports**:
- 3000: Grafana UI
- 9090: Prometheus UI
- 3100: Loki API
- 12345: Alloy UI

**Resources**:
- 2 vCPU, 2GB RAM
- 50GB disk (for metrics/logs retention)

### 3. Load Test Server (e2-medium)
**Purpose**: Performance testing and benchmarking

**Tools**:
- K6: Modern load testing
- Locust: Python-based testing
- Apache Bench: Quick HTTP benchmarks

**Resources**:
- 2 vCPU, 4GB RAM
- 20GB disk

## Network Design

### VPC & Subnet
- VPC: `{prefix}-vpc`
- Subnet: `10.0.10.0/24` (254 available IPs)
- Region: asia-northeast3 (Seoul)

### Firewall Rules
1. **SSH (22)**: All servers - from anywhere
2. **HTTP/HTTPS (80, 443)**: All servers - from anywhere
3. **Application (8080)**: Main server - from anywhere
4. **Redis (6379)**: Main server - internal subnet only
5. **Monitoring Stack (3000, 9090, 3100, 12345)**: Monitoring server - from anywhere

## Data Flow

### Metrics Collection
```
Main Server (Alloy Agent)
    ↓ (metrics scraping)
Monitoring Server (Prometheus)
    ↓ (query)
Monitoring Server (Grafana)
```

### Log Collection
```
Main Server (Alloy Agent)
    ↓ (log shipping)
Monitoring Server (Loki)
    ↓ (query)
Monitoring Server (Grafana)
```

### Load Testing
```
Load Test Server (K6/Locust)
    ↓ (HTTP requests)
Main Server (Application)
    ↓ (metrics)
Monitoring Server (Grafana)
```

## Scaling Strategy

### Current Stage (3 servers)
- ✅ Separation of concerns
- ✅ Independent management
- ✅ Cost-effective for early stage
- ✅ Easy to understand and debug

### Growth Stage (Add more as needed)

#### When to scale:
1. **Redis separation** (4th server)
   - When: Redis memory > 4-8GB
   - When: Redis becomes performance bottleneck
   - Benefits: Dedicated resources, Redis Cluster support

2. **App server scaling** (5+ servers)
   - When: CPU/Memory usage > 70%
   - When: Response time degradation
   - Add: Load balancer + multiple app servers

3. **Database server** (separate from main)
   - When: Adding PostgreSQL/MySQL
   - Benefits: Dedicated storage, easier backups

4. **Message Queue** (Kafka/RabbitMQ)
   - When: Need async processing
   - Separate server for message broker

#### Future Architecture (10+ servers):
```
Load Balancer
    ↓
App Servers (3+) ← Alloy Agents
    ↓                    ↓
Redis Cluster (3)   Monitoring Stack
    ↓                    ↑
Database (Primary + Replica)
    ↓
Message Queue (Kafka Cluster)
```

## Migration Path to Kubernetes (Optional)

If you outgrow VMs:
1. **Dockerize everything** (already done ✓)
2. **Create Kubernetes manifests** (convert docker-compose)
3. **Deploy to GKE** (managed Kubernetes)
4. **Use Helm charts** (package management)
5. **Implement auto-scaling** (HPA, VPA)

## Cost Estimation

### Current Setup (Monthly)
- Main Server (e2-medium): ~$50
- Monitoring Server (e2-small): ~$25
- Load Test Server (e2-medium): ~$50 (stop when not testing)
- Static IPs (3): ~$10
- Network egress: ~$10-20
**Total**: ~$145-155/month (with load test server stopped when not in use)

### Cost Optimization Tips
1. Stop load test server when not testing
2. Use preemptible VMs for non-critical workloads
3. Implement log retention policies (currently 31 days)
4. Consider committed use discounts for production

## Best Practices

### Security
- [ ] Change Redis password in production
- [ ] Restrict monitoring server access by IP
- [ ] Use VPN or IAP for SSH access
- [ ] Enable GCP Cloud Armor for DDoS protection

### Reliability
- [ ] Set up automated backups (Redis, configs)
- [ ] Implement health checks
- [ ] Configure alerts in Grafana
- [ ] Document incident response procedures

### Performance
- [ ] Monitor Redis memory usage
- [ ] Set up log rotation
- [ ] Implement caching strategies
- [ ] Regular load testing

### Maintenance
- [ ] Weekly: Review monitoring dashboards
- [ ] Monthly: Update Docker images
- [ ] Quarterly: Review resource utilization
- [ ] Yearly: Architecture review

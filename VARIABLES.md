# 환경 변수 관리 가이드

모든 환경 변수를 한눈에 보고 관리하는 방법입니다.

## 1. Terraform Variables (인프라 설정)

### 설정 방법

```bash
# 1. 예시 파일 복사
cp terraform.tfvars.example terraform.tfvars

# 2. 값 수정
vim terraform.tfvars

# 3. 확인
terraform console
> var.project_id
> var.region
```

### 변수 목록

| 변수 | 기본값 | 설명 | 필수 |
|------|--------|------|------|
| `prefix` | - | 리소스 이름 접두사 | ✅ |
| `project_id` | "Today-Sound" | GCP 프로젝트 ID | ✅ |
| `region` | "asia-northeast3" | GCP 리전 (서울) | ✅ |
| `zone` | "asia-northeast3-a" | GCP Zone | ✅ |
| `subnet_prefix` | "10.0.10.0/24" | Subnet CIDR | ❌ |
| `machine_type` | "e2-small" | 모니터링 서버 타입 | ❌ |
| `main_server_machine_type` | "e2-medium" | 메인 서버 타입 | ❌ |
| `environment` | "dev" | 환경 (dev/qa/prod) | ❌ |

### TFC Variables (Terraform Cloud)

TFC에서 설정하는 변수들:

**Environment Variables**:
- `GOOGLE_CREDENTIALS`: GCP Service Account JSON (Sensitive ✅)

**Terraform Variables** (선택사항, 로컬 tfvars 대신):
- `prefix`
- `project_id`
- `region`
- 등등...

## 2. Application Variables (Spring Boot)

### Main Server docker-compose.yml

```yaml
services:
  spring-app:
    environment:
      - SPRING_PROFILES_ACTIVE=${SPRING_PROFILE:-prod}
      - SPRING_REDIS_HOST=redis
      - SPRING_REDIS_PORT=6379
      - JAVA_OPTS=-Xmx512m -Xms256m
      - DB_URL=${DB_URL}
      - DB_USERNAME=${DB_USERNAME}
      - DB_PASSWORD=${DB_PASSWORD}

  alloy:
    environment:
      - MONITORING_SERVER_IP=${MONITORING_SERVER_IP}
```

### .env 파일 (Main Server)

```bash
# .env (DO NOT commit to git!)
DOCKER_REGISTRY=ghcr.io/your-username
IMAGE_TAG=latest

# Database
DB_URL=jdbc:postgresql://db-server:5432/todays_sound
DB_USERNAME=app_user
DB_PASSWORD=your-secret-password

# Monitoring
MONITORING_SERVER_IP=34.64.123.46

# Spring Boot
SPRING_PROFILE=prod
```

## 3. GitHub Secrets

GitHub Actions에서 사용하는 비밀 값들:

| Secret 이름 | 값 가져오는 방법 | 용도 |
|-------------|------------------|------|
| `TFC_TOKEN` | TFC → User Settings → Tokens | Terraform lint workflow |
| `GCP_SSH_PRIVATE_KEY` | `terraform output -raw ssh_private_key` | SSH 접속 |
| `MAIN_SERVER_IP` | `terraform output -raw main_server_ip` | 배포 대상 |
| `MONITORING_SERVER_IP` | `terraform output -raw monitoring_server_ip` | 모니터링 설정 |
| `GITHUB_TOKEN` | 자동 제공 | GitHub API |

## 4. 한눈에 보기 (Quick Reference)

### Terraform 실행 후 모든 값 확인

```bash
# 모든 output 확인
terraform output

# 특정 값만 확인
terraform output main_server_ip
terraform output monitoring_urls

# JSON 형식으로 출력
terraform output -json > outputs.json

# SSH 키 저장
terraform output -raw ssh_private_key > ~/.ssh/todays-sound.pem
chmod 600 ~/.ssh/todays-sound.pem
```

### 출력 예시

```
Outputs:

main_server_ip = "34.64.123.45"
main_server_url = "http://34.64.123.45"

monitoring_server_ip = "34.64.123.46"
monitoring_urls = {
  "alloy" = "http://34.64.123.46:12345"
  "grafana" = "http://34.64.123.46:3000"
  "loki" = "http://34.64.123.46:3100"
  "prometheus" = "http://34.64.123.46:9090"
}

loadtest_server_ip = "34.64.123.47"

servers_summary = {
  "main_server" = {
    "ip" = "34.64.123.45"
    "role" = "Application + Redis"
  }
  "monitoring_server" = {
    "ip" = "34.64.123.46"
    "role" = "Prometheus + Grafana + Loki + Alloy"
  }
  "loadtest_server" = {
    "ip" = "34.64.123.47"
    "role" = "K6 + Locust + Apache Bench"
  }
}

ssh_private_key = <sensitive>
```

### 환경 변수 체크리스트

#### 초기 설정 (한 번만)

- [ ] `terraform.tfvars` 작성
- [ ] TFC에 `GOOGLE_CREDENTIALS` 설정
- [ ] `terraform apply` 실행
- [ ] `terraform output`으로 IP 확인
- [ ] GitHub Secrets 설정:
  - [ ] `TFC_TOKEN`
  - [ ] `GCP_SSH_PRIVATE_KEY`
  - [ ] `MAIN_SERVER_IP`
  - [ ] `MONITORING_SERVER_IP`

#### Main Server 배포

- [ ] `alloy-config.alloy`에 `MONITORING_SERVER_IP` 설정
- [ ] `.env` 파일 작성 (DB 정보 등)
- [ ] `docker-compose.yml`에 환경 변수 설정
- [ ] Spring Boot `application.yml` 확인

#### Monitoring Server 배포

- [ ] `files/configs/prometheus/prometheus.yml` 설정
- [ ] `files/configs/loki/loki-config.yaml` 확인
- [ ] `files/configs/alloy/config.alloy` 확인
- [ ] `files/docker/monitoring/docker-compose.yml` 확인

## 5. 환경별 관리

### 개발 환경

```bash
# terraform-dev.tfvars
prefix = "ts-dev"
environment = "dev"
machine_type = "e2-micro"  # 비용 절약
```

```bash
terraform apply -var-file="terraform-dev.tfvars"
```

### 프로덕션 환경

```bash
# terraform-prod.tfvars
prefix = "ts-prod"
environment = "prod"
machine_type = "e2-small"
main_server_machine_type = "e2-medium"
```

```bash
terraform apply -var-file="terraform-prod.tfvars"
```

## 6. 보안 Best Practices

### ❌ 절대 커밋하지 말 것

```
terraform.tfvars
*.tfvars (except .example)
.env
.env.local
*.pem
*.key
terraform.tfstate
terraform.tfstate.backup
```

### ✅ .gitignore 확인

이미 `.gitignore`에 포함되어 있어야 함:
```gitignore
*.tfvars
!*.tfvars.example
.env
.env.*
*.pem
*.key
*.tfstate*
```

### ✅ 비밀 값 관리

1. **Terraform Cloud**: `GOOGLE_CREDENTIALS`
2. **GitHub Secrets**: SSH 키, 서버 IP
3. **Docker Secrets**: DB 비밀번호 등
4. **환경 변수 파일**: `.env` (서버에만 존재)

## 7. 트러블슈팅

### 변수를 찾을 수 없다는 에러

```bash
# 1. variables.tf에 정의되어 있는지 확인
grep "variable \"project_id\"" variables.tf

# 2. tfvars 파일이 있는지 확인
ls -la *.tfvars

# 3. TFC Variables 확인
# app.terraform.io → Workspace → Variables
```

### 출력 값이 안 보일 때

```bash
# 1. terraform apply가 성공했는지 확인
terraform show

# 2. output이 정의되어 있는지 확인
grep "output" outputs.tf

# 3. 강제로 다시 읽기
terraform refresh
terraform output
```

### 환경 변수가 전달되지 않을 때

```bash
# Docker Compose에서 확인
docker compose config  # 실제 적용된 환경 변수 확인

# 컨테이너 내부에서 확인
docker exec spring-app env | grep SPRING_
```

## 8. 요약

```
┌─────────────────────────────────────────────────────┐
│ 환경 변수 플로우                                    │
└─────────────────────────────────────────────────────┘

1. Terraform Variables (terraform.tfvars)
   ↓ terraform apply
   ↓
2. Terraform Outputs (IP, URLs 등)
   ↓ 수동 복사
   ↓
3. GitHub Secrets (CI/CD용)
   ↓ CI/CD 실행 시
   ↓
4. Server .env 파일 (애플리케이션용)
   ↓ docker-compose up
   ↓
5. Container Environment Variables
```

**핵심**:
- Terraform은 인프라 변수만
- Application 변수는 `.env` + docker-compose
- 비밀 값은 TFC/GitHub Secrets
- 모든 값은 `terraform output`으로 확인

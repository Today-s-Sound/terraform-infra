# Terraform과 CI/CD 통합 가이드

## 핵심 개념

```
┌─────────────────────────────────────────────────────────┐
│                    전체 워크플로우                       │
└─────────────────────────────────────────────────────────┘

1. Terraform (Infrastructure) - 한 번만
   ├─ VM 생성
   ├─ 네트워크 설정
   ├─ Docker 설치
   └─ 디렉토리 생성 (/home/ubuntu/app)

2. GitHub Actions (Application) - 매 커밋마다
   ├─ Spring Boot 빌드
   ├─ Docker 이미지 빌드
   ├─ 이미지 푸시
   └─ SSH로 docker-compose up -d
```

## 왜 이렇게 분리하나요?

### Terraform의 문제점 (애플리케이션 배포)
- ❌ 매번 `terraform apply` 실행해야 함
- ❌ State 관리 복잡
- ❌ 롤백 어려움
- ❌ Blue-Green 배포 불가능

### CI/CD의 장점 (애플리케이션 배포)
- ✅ 코드 푸시 → 자동 배포
- ✅ 빠른 배포 (30초-2분)
- ✅ 쉬운 롤백 (이전 이미지로 재배포)
- ✅ 배포 이력 관리

## 실전 예시

### 시나리오 1: 처음 프로젝트 시작

```bash
# 1. Terraform으로 인프라 구축 (처음 한 번)
cd terraform-infra
terraform init
terraform apply

# 출력: 서버 IP 주소들
# Main Server: 34.64.123.45
# Monitoring: 34.64.123.46

# 2. GitHub Secrets 설정
# MAIN_SERVER_IP=34.64.123.45
# GCP_SSH_PRIVATE_KEY=<terraform output>

# 3. Spring Boot 코드 푸시
cd ../backend
git add .
git commit -m "Initial commit"
git push origin main

# → GitHub Actions 자동 실행!
# → 서버에 자동 배포됨

# 4. 확인
curl http://34.64.123.45:8080/actuator/health
```

### 시나리오 2: 기능 개발 및 배포

```bash
# 1. Spring Boot 코드 수정
vim src/main/java/com/example/Controller.java

# 2. 커밋 & 푸시
git add .
git commit -m "Add new API endpoint"
git push origin main

# → GitHub Actions가 자동으로:
#   1. 빌드
#   2. 테스트
#   3. Docker 이미지 생성
#   4. 서버에 배포

# Terraform은 건드리지 않음!
```

### 시나리오 3: 인프라 변경 (서버 추가)

```bash
# 서버를 추가해야 할 때만 Terraform 사용

cd terraform-infra

# 1. Terraform 코드 수정
vim servers/app-server-2.tf

# 2. Apply
terraform apply

# 3. GitHub Secrets에 새 서버 IP 추가

# 4. CI/CD 워크플로우 수정 (2대 서버에 배포)
```

## Repository 구조별 전략

### Option 1: 모노레포 (추천: 소규모)

```
Todays_Sound/
├── terraform-infra/
│   ├── main.tf
│   └── servers/
├── backend/                 # Spring Boot
│   ├── src/
│   ├── Dockerfile
│   └── docker-compose.yml
├── frontend/                # React/Vue (선택)
└── .github/workflows/
    ├── infra.yml           # Terraform (수동 트리거)
    └── deploy-backend.yml  # Spring Boot (자동)
```

**장점**: 한 곳에서 관리, 쉬운 통합
**단점**: 큰 저장소, 느린 CI/CD

### Option 2: 멀티 레포 (추천: 대규모)

```
infrastructure/             # Terraform 전용
├── main.tf
└── servers/

todays-sound-backend/       # Spring Boot 전용
├── src/
├── Dockerfile
├── docker-compose.yml
└── .github/workflows/
    └── deploy.yml

todays-sound-frontend/      # Frontend 전용
```

**장점**: 명확한 분리, 빠른 CI/CD
**단점**: 여러 저장소 관리

## CI/CD 파이프라인 예시

### 1. 개발 환경

```yaml
# .github/workflows/dev.yml
on:
  push:
    branches: [develop]

jobs:
  deploy-dev:
    steps:
      - Build & Test
      - Deploy to Dev Server
      - Run integration tests
```

### 2. 프로덕션 환경

```yaml
# .github/workflows/prod.yml
on:
  push:
    branches: [main]

jobs:
  deploy-prod:
    steps:
      - Build & Test
      - Security scan
      - Deploy to Prod Server (Blue-Green)
      - Health check
      - Rollback if failed
```

## 배포 전략

### Rolling Update (현재 권장)

```yaml
# docker-compose.yml에서
services:
  app:
    image: my-app:${TAG}
    deploy:
      update_config:
        parallelism: 1
        delay: 10s
```

```bash
# 배포 시
docker compose up -d --no-deps --build app
```

### Blue-Green (나중에)

```bash
# 1. Green 배포
docker compose -f docker-compose.green.yml up -d

# 2. Health check
curl http://localhost:8081/health

# 3. 트래픽 전환 (Nginx/Load Balancer)
nginx -s reload

# 4. Blue 종료
docker compose -f docker-compose.blue.yml down
```

## Terraform Provisioner 최소화

**❌ 하지 말아야 할 것**:
```hcl
resource "null_resource" "deploy_app" {
  provisioner "remote-exec" {
    inline = [
      "docker compose pull",
      "docker compose up -d"
    ]
  }

  # 문제:
  # 1. 코드 변경마다 terraform apply 필요
  # 2. State 복잡도 증가
  # 3. 롤백 어려움
}
```

**✅ 해야 할 것**:
```hcl
resource "null_resource" "initial_setup" {
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install -y docker.io",
      "mkdir -p /home/ubuntu/app"
    ]
  }

  # 초기 설정만!
  # 앱 배포는 CI/CD가 담당
}
```

## 환경 변수 관리

### Terraform (인프라 레벨)
```hcl
variable "project_id" {
  description = "GCP Project ID"
}

variable "region" {
  default = "asia-northeast3"
}
```

### CI/CD (애플리케이션 레벨)
```yaml
env:
  SPRING_PROFILES_ACTIVE: prod
  JAVA_OPTS: "-Xmx512m"
```

### Docker Compose (런타임)
```yaml
services:
  app:
    environment:
      - SPRING_REDIS_HOST=redis
      - DB_HOST=${DB_HOST}  # .env 파일에서
```

## 비용 최적화

### Terraform 비용 줄이기
```hcl
# 1. Spot/Preemptible VM
resource "google_compute_instance" "main" {
  machine_type = "e2-small"
  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

# 2. 필요시만 켜기
resource "google_compute_instance" "loadtest" {
  # count = var.enable_loadtest ? 1 : 0
}
```

### 월 $20 구성 (Spot VM)
```
Main (e2-small, spot): $4
Monitoring (e2-micro, spot): $2
Static IPs: $3
──────────────────────────
총: ~$9/월
```

### 월 $50 구성 (On-demand)
```
Main (e2-medium): $28
Monitoring (e2-small): $14
Static IPs: $6
──────────────────────────
총: ~$48/월
```

## 체크리스트

### 초기 설정 (한 번만)
- [ ] Terraform으로 인프라 구축
- [ ] Terraform outputs에서 IP 확인
- [ ] GitHub Secrets 설정
- [ ] docker-compose.yml 작성
- [ ] CI/CD 워크플로우 작성

### 매일 개발
- [ ] 코드 수정
- [ ] git push (자동 배포됨)
- [ ] Health check 확인
- [ ] Monitoring 확인

### 인프라 변경 (가끔)
- [ ] Terraform 코드 수정
- [ ] terraform plan 확인
- [ ] terraform apply
- [ ] CI/CD 설정 업데이트

## FAQ

**Q: Spring Boot 코드 변경할 때마다 Terraform 실행?**
A: ❌ 아니요! CI/CD가 자동으로 배포합니다.

**Q: docker-compose.yml 변경하면?**
A: CI/CD에서 파일을 서버에 복사하고 재시작합니다.

**Q: Terraform은 언제 실행?**
A: 서버 추가/삭제, 네트워크 변경 등 인프라 변경시만.

**Q: 롤백은?**
A: CI/CD에서 이전 Docker 이미지로 재배포합니다.

**Q: 비용이 너무 높으면?**
A: Spot VM 사용하거나 서버 통합 (Main + Monitoring).

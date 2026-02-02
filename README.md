# Terraform GCP Infrastructure with TFC (VCS-driven)

GCP Compute Engine 인프라를 Terraform Cloud VCS-driven workflow로 관리하는 모노레포입니다.

## Repository 구조

```
terraform-infra/
├── main.tf                    # GCP 인프라 리소스
├── variables.tf               # 변수 정의
├── outputs.tf                 # 출력 값
├── files/
│   ├── docker/
│   │   └── monitoring/        # Docker Compose (Prometheus, Grafana, Loki, Alloy)
│   ├── configs/
│   │   ├── prometheus/        # Prometheus 설정
│   │   ├── grafana/           # Grafana datasources
│   │   ├── loki/              # Loki 설정
│   │   └── alloy/             # Alloy 설정
│   └── scripts/
│       ├── deploy_app.sh
│       ├── setup-docker.sh
│       └── deploy-monitoring.sh
└── .github/workflows/
    ├── terraform.yml          # Lint 체크
    ├── deploy-app.yml         # 자동 배포
    └── manage-services.yml    # 서비스 관리
```

## 인프라 구성

- **Provider**: Google Cloud Platform
- **리전**: asia-northeast3 (서울)
- **리소스**: VPC, Subnet, Firewall, Compute Instance, Static IP

## 모니터링 스택

- **Prometheus**: 메트릭 수집 및 저장
- **Grafana**: 시각화 대시보드
- **Loki**: 로그 수집 및 분석
- **Alloy**: 텔레메트리 수집기 (메트릭, 로그, 트레이스)

## 사전 설정

### 1. Terraform Cloud 설정 (VCS-driven)

#### Step 1: Workspace 생성
1. [Terraform Cloud](https://app.terraform.io) 로그인
2. New Workspace → **Version control workflow** 선택
3. GitHub 연결 및 repository 선택
4. Workspace 이름: `terraform-gcp-tfc-workflow`

#### Step 2: Workspace 설정
- **Settings → General**
  - Terraform Working Directory: 비워두기 (루트)
  - Auto apply: 원하는 경우 활성화 (권장: 비활성화하고 수동 승인)

#### Step 3: Environment Variables 설정
- **Variables 탭 → Environment Variables**
  - `GOOGLE_CREDENTIALS`: GCP Service Account JSON (Sensitive 체크)

#### Step 4: Terraform Variables 설정 (선택)
- `prefix`: 리소스 이름 접두사
- `project_id`: GCP 프로젝트 ID (기본값: Today-Sound)
- `region`: GCP 리전 (기본값: asia-northeast3)

### 2. GitHub Secrets 설정

Repository Settings → Secrets and variables → Actions에서 다음 Secrets 추가:

#### 필수 Secrets:
1. `TFC_TOKEN`: Terraform Cloud API Token (lint workflow용)
   - [TFC → User Settings → Tokens](https://app.terraform.io/app/settings/tokens)

2. `GCP_SSH_PRIVATE_KEY`: SSH Private Key (애플리케이션 배포용)
   - Terraform 첫 실행 후: `terraform output -raw ssh_private_key` 복사
   - 또는 TFC UI에서 outputs 확인

3. `GCP_INSTANCE_IP`: GCP Instance Public IP
   - Terraform 첫 실행 후: `terraform output -raw instance_ip` 복사
   - 또는 TFC UI에서 outputs 확인

## 워크플로우

### 1. 인프라 관리 (Terraform Cloud - VCS-driven)

#### Pull Request 생성 시 (*.tf 파일 변경):
1. GitHub Actions: `terraform fmt` & `terraform validate` 체크
2. **TFC 자동 트리거**: Speculative Plan 실행
3. PR에서 Plan 결과 확인

#### Main 브랜치 Merge 시:
1. **TFC 자동 트리거**: Plan 실행
2. TFC UI에서 Confirm & Apply
3. 인프라 프로비저닝 (VM, VPC, 네트워크)
4. 초기 설정: Docker 설치

### 2. 애플리케이션 배포 (GitHub Actions)

#### 자동 배포 (files/ 디렉토리 변경 시):
1. `files/**` 변경 감지
2. SSH로 서버 접속
3. 파일 자동 배포
4. Commit 메시지에 `[deploy-monitoring]` 포함 시 자동 시작

#### 수동 서비스 관리:
- **Actions 탭** → **Manage Services** → **Run workflow**
- 선택 가능한 작업:
  - `restart-all`: 모든 서비스 재시작
  - `restart-monitoring`: 모니터링 스택만 재시작
  - `stop-monitoring`: 모니터링 스택 중지
  - `logs-monitoring`: 로그 확인

## 로컬 개발

```bash
# 초기화
terraform init

# Plan 확인 (TFC에서 실행됨)
terraform plan

# Apply (TFC에서 실행됨)
terraform apply
```

## 사용 예시

### 모니터링 설정 변경하기

```bash
# 1. Prometheus 설정 수정
vim files/configs/prometheus/prometheus.yml

# 2. Git commit & push
git add files/configs/prometheus/prometheus.yml
git commit -m "Update prometheus scrape config [deploy-monitoring]"
git push origin main

# 3. 자동 배포됨 (GitHub Actions)
# 또는 수동 재시작: Actions → Manage Services → restart-monitoring
```

### Docker Compose 수정하기

```bash
# 1. 서비스 추가 (예: Node Exporter)
vim files/docker/monitoring/docker-compose.yml

# 2. Git commit & push
git add files/docker/monitoring/docker-compose.yml
git commit -m "Add node-exporter to monitoring stack [deploy-monitoring]"
git push origin main

# 3. 자동으로 배포되고 재시작됨
```

### 서비스 재시작 (긴급 상황)

1. GitHub → Actions 탭
2. **Manage Services** 선택
3. **Run workflow** 클릭
4. Action 선택 (restart-monitoring)
5. **Run workflow** 실행

### Loki 로그 확인하기

Grafana에서 Loki로 로그 조회:
1. Grafana → Explore
2. Data source: **Loki** 선택
3. 로그 쿼리 예시:
   ```logql
   # 모든 Docker 컨테이너 로그
   {container=~".+"}

   # Prometheus 컨테이너 로그만
   {container="prometheus"}

   # 에러 로그만
   {container=~".+"} |= "error"

   # 시스템 로그
   {job="system"}
   ```

### 직접 SSH 접속 (비상 시)

```bash
# SSH key는 terraform output에서 확인
terraform output -raw ssh_private_key > ~/.ssh/gcp-key.pem
chmod 600 ~/.ssh/gcp-key.pem

# SSH 접속
ssh -i ~/.ssh/gcp-key.pem ubuntu@$(terraform output -raw instance_ip)

# 컨테이너 상태 확인
cd ~/docker/monitoring
docker compose ps
docker compose logs

# 특정 서비스 로그 확인
docker compose logs -f prometheus
docker compose logs -f loki
docker compose logs -f alloy
```

## Best Practices

### 역할 분리
- **Terraform**: 인프라만 (VM, 네트워크, 초기 설정)
- **GitHub Actions**: 애플리케이션 배포 및 관리
- **수동 SSH**: 긴급 상황이나 디버깅 시에만

### 워크플로우
1. **인프라 변경**: `*.tf` 수정 → PR → TFC Plan → Merge → Apply
2. **애플리케이션 배포**: `files/` 수정 → Push → 자동 배포
3. **서비스 재시작**: GitHub Actions manual trigger
4. **긴급 상황**: SSH 직접 접속

### 보안
- SSH 키는 GitHub Secrets에만 저장
- `.tfvars`에 민감 정보 저장 금지 (TFC Variables 사용)
- Auto apply는 신중하게 사용

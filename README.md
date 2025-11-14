# Load Test Server

Go로 작성된 고성능 부하테스트용 서버입니다. Locust를 사용하여 다양한 시나리오의 부하 테스트를 수행할 수 있습니다.

## 특징

- **고성능 Go 서버**: net/http 기반의 빠르고 안정적인 서버
- **다양한 테스트 엔드포인트**: CPU, 메모리, 지연, 에러 등 다양한 시나리오 지원
- **Locust 통합**: Python 기반의 강력한 부하테스트 도구
- **Docker 지원**: 쉬운 배포와 확장
- **실시간 통계**: 서버 상태와 성능 메트릭 제공

## 사용 가능한 엔드포인트

| 엔드포인트 | 메서드 | 설명 |
|----------|--------|------|
| `/` | GET | 서버 정보 |
| `/health` | GET | 빠른 헬스체크 (기본 응답) |
| `/cpu` | GET | CPU 집약적 작업 (계산) |
| `/slow` | GET | 지연 응답 (100-500ms) |
| `/memory` | GET | 메모리 집약적 작업 (10MB 할당) |
| `/json` | POST | JSON 파싱 테스트 |
| `/error` | GET | 랜덤 에러 (30% 확률로 500 에러) |
| `/stats` | GET | 서버 통계 (요청 수, 메모리, 고루틴 등) |
| `/large` | GET | 대용량 응답 (1MB JSON) |

## 빠른 시작

### 방법 1: Docker Compose 사용 (권장)

```bash
# 모든 서비스 실행 (서버 + Locust)
docker-compose up -d

# 서버 확인
curl http://localhost:8080/health

# Locust 웹 UI 접속
# 브라우저에서 http://localhost:8089 접속
# Host: http://server:8080
# 사용자 수와 증가율 설정 후 테스트 시작
```

### 방법 2: 로컬 실행

**서버 실행:**
```bash
# Go 설치 필요 (https://golang.org/dl/)
go run main.go

# 또는 빌드 후 실행
go build -o server main.go
./server
```

**Locust 실행:**
```bash
# Python과 Locust 설치 필요
pip install locust

# Locust 웹 UI 모드로 실행
locust -f locustfile.py --host=http://localhost:8080

# 브라우저에서 http://localhost:8089 접속
```

## Locust 사용 예시

### 웹 UI 사용
```bash
# 기본 실행
locust -f locustfile.py --host=http://localhost:8080

# 브라우저에서 http://localhost:8089 접속하여:
# - Number of users: 100 (동시 사용자 수)
# - Spawn rate: 10 (초당 증가하는 사용자 수)
# - Host: http://localhost:8080
```

### Headless 모드 (CLI)
```bash
# 100명 사용자, 초당 10명씩 증가, 60초 동안 실행
locust -f locustfile.py --host=http://localhost:8080 \
  --users 100 --spawn-rate 10 --run-time 60s --headless

# 스트레스 테스트 (500명 사용자)
locust -f locustfile.py --host=http://localhost:8080 \
  --user StressTestUser --users 500 --spawn-rate 50 --headless

# Health Check만 집중 테스트
locust -f locustfile.py --host=http://localhost:8080 \
  --user HealthCheckUser --users 1000 --spawn-rate 100 --headless
```

### 분산 실행 (대규모 부하)
```bash
# 마스터 노드
locust -f locustfile.py --master --host=http://localhost:8080

# 워커 노드 (다른 터미널이나 서버에서)
locust -f locustfile.py --worker --master-host=localhost
locust -f locustfile.py --worker --master-host=localhost
locust -f locustfile.py --worker --master-host=localhost
```

## 사용자 클래스

Locust 스크립트에는 여러 사용자 클래스가 정의되어 있습니다:

1. **WebsiteUser** (기본): 모든 엔드포인트를 가중치에 따라 호출
2. **StressTestUser**: 짧은 대기시간으로 높은 부하 생성
3. **HealthCheckUser**: `/health` 엔드포인트만 집중 테스트
4. **CpuIntensiveUser**: CPU 집약적 엔드포인트만 테스트

## 통계 확인

실시간 서버 통계:
```bash
curl http://localhost:8080/stats | jq
```

응답 예시:
```json
{
  "total_requests": 15432,
  "total_errors": 523,
  "goroutines": 47,
  "memory_usage_mb": 12.45,
  "uptime": "5m23.456s"
}
```

## Docker 명령어

```bash
# 빌드 및 실행
docker-compose up --build -d

# 로그 확인
docker-compose logs -f server
docker-compose logs -f locust-master

# 워커 스케일링 (부하 증가)
docker-compose up -d --scale locust-worker=5

# 중지
docker-compose down

# 완전 삭제 (볼륨 포함)
docker-compose down -v
```

## 성능 튜닝

### Go 서버
```bash
# GOMAXPROCS 설정 (CPU 코어 수)
GOMAXPROCS=8 go run main.go

# 최적화된 빌드
go build -ldflags="-s -w" -o server main.go
```

### Locust
- 더 많은 부하: 워커 수 증가 (`--scale locust-worker=N`)
- 네트워크 최적화: 동일 네트워크에서 실행
- 리소스 모니터링: `docker stats`로 컨테이너 리소스 확인

## 테스트 시나리오 예시

### 1. 기본 성능 테스트
```bash
locust -f locustfile.py --host=http://localhost:8080 \
  --users 100 --spawn-rate 10 --run-time 5m --headless
```

### 2. 스파이크 테스트
```bash
locust -f locustfile.py --host=http://localhost:8080 \
  --users 1000 --spawn-rate 100 --run-time 1m --headless
```

### 3. 내구성 테스트
```bash
locust -f locustfile.py --host=http://localhost:8080 \
  --users 50 --spawn-rate 5 --run-time 1h --headless
```

### 4. CPU 스트레스 테스트
```bash
locust -f locustfile.py --host=http://localhost:8080 \
  --user CpuIntensiveUser --users 200 --spawn-rate 20 --headless
```

## 트러블슈팅

### 포트 충돌
```bash
# 사용 중인 포트 확인
lsof -i :8080
lsof -i :8089

# docker-compose.yml에서 포트 변경
```

### 메모리 부족
```bash
# Docker 메모리 제한 증가
# docker-compose.yml의 서비스에 추가:
# mem_limit: 2g
# memswap_limit: 2g
```

### Go 서버가 응답하지 않음
```bash
# 로그 확인
docker-compose logs server

# 헬스체크 확인
docker-compose ps
```

## 요구사항

- **Go**: 1.21 이상 (로컬 실행 시)
- **Python**: 3.8 이상 (Locust 로컬 실행 시)
- **Docker**: 20.10 이상 (Docker 실행 시)
- **Docker Compose**: 2.0 이상

## 라이선스

MIT License

## 기여

이슈와 PR을 환영합니다!
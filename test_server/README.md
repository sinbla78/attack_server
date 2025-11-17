# 로컬 테스트 서버

다양한 부하테스트 시나리오를 제공하는 Go 기반 테스트 서버

## 특징

다양한 엔드포인트를 통해 실제 서버 부하 상황을 시뮬레이션할 수 있습니다.

## 엔드포인트

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

```bash
# 서버 실행
go run main.go

# 서버가 http://localhost:8080 에서 실행됨
```

## 테스트 방법

### 1. curl로 테스트
```bash
# 헬스체크
curl http://localhost:8080/health

# 통계 확인
curl http://localhost:8080/stats | jq

# CPU 부하
curl http://localhost:8080/cpu
```

### 2. 부하테스트 도구 사용
```bash
# 상위 디렉토리의 go_loadtest 사용
cd ../go_loadtest
./run_go_test.sh
# 3 선택 (localhost:8080)

# 또는 python Locust 사용
cd ../python
locust -f locustfile.py --host=http://localhost:8080
# 브라우저에서 http://localhost:8089 접속
```

## 빌드

```bash
# 최적화된 빌드
go build -ldflags="-s -w" -o server main.go

# 실행
./server
```

## 사용 예시

### 기본 성능 테스트
```bash
# 터미널 1: 서버 실행
go run main.go

# 터미널 2: 부하테스트
cd ../go_loadtest
go run loadtest.go -url=http://localhost:8080/health -n=1000 -c=50
```

### CPU 부하 테스트
```bash
cd ../go_loadtest
go run loadtest.go -url=http://localhost:8080/cpu -n=100 -c=10
```

### 지연 응답 테스트
```bash
cd ../go_loadtest
go run loadtest.go -url=http://localhost:8080/slow -n=100 -c=10
```

## 통계 정보

`/stats` 엔드포인트에서 실시간 서버 통계를 확인할 수 있습니다:

```json
{
  "total_requests": 15432,
  "total_errors": 523,
  "goroutines": 47,
  "memory_usage_mb": 12.45,
  "uptime": "5m23.456s"
}
```

## 포트 변경

기본 포트는 8080입니다. 변경하려면 `main.go`의 `port` 변수를 수정하세요:

```go
port := ":8888"  // 8888 포트로 변경
```

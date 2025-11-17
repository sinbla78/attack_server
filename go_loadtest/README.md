# Go 부하테스트 도구

간단하고 빠른 Go 기반 HTTP 부하테스트 클라이언트

## 특징

- ✅ **설치 불필요** - Go만 있으면 바로 실행
- ✅ **빠르고 가벼움** - Go의 고루틴 활용
- ✅ **실시간 진행률** - 초당 RPS 표시
- ✅ **두 가지 모드** - 요청 수 기반 / 시간 기반
- ✅ **Keep-Alive 지원** - 성능 최적화

## 빠른 시작

### 방법 1: 대화형 스크립트 (권장)
```bash
./run_go_test.sh
```

선택 옵션:
1. 서버 선택 (dev/live/localhost/직접입력)
2. 테스트 모드 (요청 수 기반/시간 기반)
3. 부하 설정 입력

### 방법 2: 직접 실행
```bash
# 기본 테스트 (100개 요청, 10명 동시)
go run loadtest.go -url=https://dev.stagelives.com/api/health -n=100 -c=10

# 시간 기반 (30초 동안, 20명 동시)
go run loadtest.go -url=https://dev.stagelives.com/api/health -n=0 -d=30 -c=20

# 고부하 테스트 (1000개 요청, 100명 동시)
go run loadtest.go -url=http://localhost:8080/cpu -n=1000 -c=100
```

## 옵션

| 옵션 | 설명 | 기본값 |
|-----|------|-------|
| `-url` | 대상 URL | `http://localhost:8080/health` |
| `-n` | 총 요청 수 (0이면 시간 기반) | `100` |
| `-d` | 테스트 지속 시간(초) | `10` |
| `-c` | 동시 사용자 수 | `10` |
| `-m` | HTTP 메서드 | `GET` |
| `-t` | 요청 타임아웃(초) | `30` |
| `-k` | Keep-Alive 사용 여부 | `true` |

## 사용 예시

### 1. Dev 서버 빠른 테스트
```bash
go run loadtest.go \
  -url=https://dev.stagelives.com/api/health \
  -n=100 -c=10
```

### 2. 시간 기반 스트레스 테스트
```bash
go run loadtest.go \
  -url=https://dev.stagelives.com/api/users \
  -n=0 -d=60 -c=50
```

### 3. POST 요청 테스트
```bash
go run loadtest.go \
  -url=https://dev.stagelives.com/api/data \
  -m=POST -n=200 -c=20
```

### 4. 로컬 서버 고부하 테스트
```bash
go run loadtest.go \
  -url=http://localhost:8080/cpu \
  -n=1000 -c=100
```

## 결과 해석

```
🚀 Go 부하테스트 시작
=====================================
대상 URL: https://dev.stagelives.com/api/health
HTTP 메서드: GET
동시 사용자 수: 10
총 요청 수: 100
타임아웃: 30s
Keep-Alive: true
=====================================
진행중... 총 요청: 100 | 성공: 98 | 실패: 2 | RPS: 45

=====================================
📊 부하테스트 결과
=====================================
총 요청 수: 100
성공: 98 (98.00%)
실패: 2 (2.00%)
총 소요 시간: 2.234s
RPS (초당 요청 수): 44.76
평균 응답 시간: 223ms
평균 처리량: 44.76 req/sec
=====================================
```

**지표 설명:**
- **성공률**: 95% 이상이 정상
- **RPS**: 서버가 처리할 수 있는 초당 요청 수
- **평균 응답 시간**: 낮을수록 좋음 (일반적으로 200ms 이하 권장)
- **실패**: 5% 미만 권장

## 빌드 및 배포

```bash
# 빌드
go build -o loadtest loadtest.go

# 실행 (빌드 후가 더 빠름)
./loadtest -url=https://dev.stagelives.com/api/health -n=100 -c=10

# 크로스 컴파일 (Linux용)
GOOS=linux GOARCH=amd64 go build -o loadtest-linux loadtest.go
```

## 제한사항

- **복잡한 시나리오**: 단순 HTTP 요청만 지원 (세션 관리 등 복잡한 기능은 python/Locust 사용)
- **Request Body**: 현재 지원 안 함 (추가 개발 필요)
- **인증**: 기본 HTTP 인증만 가능

복잡한 시나리오는 `../python/` 디렉토리의 Locust를 사용하세요.

## 트러블슈팅

### SSL 인증서 오류
코드에서 `InsecureSkipVerify: true`로 설정되어 있어 개발 환경에서 자체 서명 인증서도 허용합니다.

### 타임아웃 발생
```bash
# 타임아웃 시간 증가
go run loadtest.go -url=... -t=60
```

### 동시 연결 제한
OS 레벨에서 파일 디스크립터 제한을 확인하세요:
```bash
ulimit -n
# 제한 증가
ulimit -n 10000
```

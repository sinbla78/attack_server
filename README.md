# 부하테스트 도구 모음

다양한 용도의 부하테스트를 위한 도구 모음

## 📂 프로젝트 구조

```
attack_server/
├── test_server/         # 로컬 테스트 서버 (Go)
│   ├── main.go
│   ├── go.mod
│   └── README.md
│
├── node_loadtest/       # Node.js 테스트 서버 (TypeScript)
│   ├── src/
│   │   └── server.ts
│   ├── package.json
│   ├── tsconfig.json
│   ├── run.sh
│   └── README.md
│
├── go_loadtest/         # Go 부하테스트 클라이언트
│   ├── loadtest.go
│   ├── run_go_test.sh
│   ├── go.mod
│   └── README.md
│
├── python/              # Python Locust 부하테스트
│   ├── locustfile.py
│   ├── stagelives_test.py
│   ├── run_test.sh
│   └── README.md
│
└── README.md            # 이 파일
```

---

## 🚀 빠른 시작

### 방법 1: Go 부하테스트 (가장 간단)
```bash
cd go_loadtest
./run_go_test.sh
```
- ✅ 설치 불필요 (Go만 있으면 됨)
- ✅ 빠르고 가벼움
- ✅ 간단한 부하테스트에 적합
- ✅ 즉시 결과 확인

### 방법 2: Python Locust (고급 기능)
```bash
cd python
./run_test.sh
```
- ✅ 웹 UI 제공 (실시간 그래프)
- ✅ 복잡한 시나리오 작성 가능
- ✅ 세션 기반 테스트 지원
- ✅ 분산 실행 가능

### 방법 3: 로컬 테스트 서버 (Go)
```bash
cd test_server
go run main.go
```
- ✅ 다양한 시나리오 엔드포인트 제공
- ✅ CPU/메모리 부하, 지연, 에러 등
- ✅ 개발 환경 테스트용

### 방법 4: Node.js 테스트 서버 (TypeScript)
```bash
cd node_loadtest
./run.sh
```
- ✅ TypeScript로 타입 안전성 제공
- ✅ Express 기반 빠른 성능
- ✅ 비동기 I/O로 높은 동시성
- ✅ npm 생태계 활용

---

## 📋 각 도구 상세 설명

### 1️⃣ test_server/ - Go 로컬 테스트 서버

다양한 부하 시나리오를 제공하는 Go 기반 테스트 서버

**엔드포인트:**
- `/health` - 빠른 헬스체크
- `/cpu` - CPU 집약적 작업
- `/slow` - 지연 응답 (100-500ms)
- `/memory` - 메모리 부하 (10MB)
- `/json` - POST JSON 파싱
- `/error` - 랜덤 에러 (30%)
- `/stats` - 서버 통계
- `/large` - 대용량 응답 (1MB)

**사용법:**
```bash
cd test_server
go run main.go
# http://localhost:8080
```

👉 [상세 문서 보기](test_server/README.md)

---

### 2️⃣ node_loadtest/ - Node.js 테스트 서버

TypeScript + Express 기반의 고성능 테스트 서버

**특징:**
- TypeScript로 타입 안전성
- 비동기 I/O (이벤트 루프)
- 실시간 통계 추적
- 스트리밍 응답 지원

**엔드포인트:**
- `/health` - 헬스체크
- `/cpu` - CPU 집약적 작업 (Fibonacci)
- `/slow` - 지연 응답 (100-500ms)
- `/memory` - 메모리 부하 (10MB)
- `/json` - POST JSON 파싱
- `/error` - 랜덤 에러 (30%)
- `/stats` - 서버 통계
- `/large` - 대용량 응답 (1MB)
- `/async` - 비동기 작업 테스트
- `/stream` - 스트리밍 응답

**사용법:**
```bash
cd node_loadtest
./run.sh
# http://localhost:8080
```

👉 [상세 문서 보기](node_loadtest/README.md)

---

### 3️⃣ go_loadtest/ - Go 부하테스트 클라이언트

간단하고 빠른 HTTP 부하테스트 도구

**특징:**
- 설치 불필요 (Go만 필요)
- 실시간 진행률 표시
- 요청 수 / 시간 기반 테스트
- Keep-Alive 지원

**사용법:**
```bash
cd go_loadtest

# 대화형 스크립트
./run_go_test.sh

# 직접 실행
go run loadtest.go -url=https://dev.stagelives.com/api/health -n=100 -c=10
```

**주요 옵션:**
- `-url`: 대상 URL
- `-n`: 총 요청 수 (0이면 시간 기반)
- `-d`: 테스트 지속 시간(초)
- `-c`: 동시 사용자 수

👉 [상세 문서 보기](go_loadtest/README.md)

---

### 4️⃣ python/ - Python Locust 부하테스트

고급 기능을 제공하는 부하테스트 도구

**특징:**
- 웹 UI (http://localhost:8089)
- 세션 기반 인증 (로그인 후 세션 유지)
- 복잡한 사용자 시나리오
- 실시간 그래프

**파일:**
- `locustfile.py` - 로컬 서버용
- `stagelives_test.py` - StageLives용 (세션 기반)
- `run_test.sh` - 대화형 실행

**사용자 클래스:**
- `StageLivesUser` - 일반 사용자 (세션 유지)
- `StageLivesStressUser` - 스트레스 테스트
- `StageLivesAuthUser` - 로그인/로그아웃 테스트

**사용법:**
```bash
cd python

# 대화형 스크립트
./run_test.sh

# 웹 UI
locust -f stagelives_test.py --host=https://dev.stagelives.com

# Headless
locust -f stagelives_test.py --host=https://dev.stagelives.com \
  --users 50 --spawn-rate 10 --run-time 60s --headless
```

👉 [상세 문서 보기](python/README.md)

---

## 🎯 사용 시나리오별 추천

### 간단한 API 엔드포인트 테스트
**➡️ go_loadtest 사용**
```bash
cd go_loadtest
./run_go_test.sh
```
- 빠르고 간단
- 즉시 결과 확인
- 설정 최소화

### 세션 기반 웹 애플리케이션 테스트
**➡️ python Locust 사용**
```bash
cd python
./run_test.sh
```
- 로그인 세션 유지
- 복잡한 사용자 행동
- 웹 UI로 실시간 모니터링

### 로컬 개발 환경 테스트
**➡️ test_server/node_loadtest + go_loadtest/python**
```bash
# 터미널 1: Go 서버
cd test_server
go run main.go

# 또는 Node.js 서버
cd node_loadtest
./run.sh

# 터미널 2: 부하테스트
cd go_loadtest
go run loadtest.go -url=http://localhost:8080/cpu -n=100 -c=10
```
- 다양한 시나리오 테스트
- 개발 단계 성능 확인
- Go vs Node.js 성능 비교

---

## 📊 테스트 예시

### 예시 1: Dev 서버 빠른 테스트
```bash
cd go_loadtest
go run loadtest.go \
  -url=https://dev.stagelives.com/api/health \
  -n=100 -c=10
```

### 예시 2: Live 서버 스트레스 테스트
```bash
cd python
locust -f stagelives_test.py --host=https://live.stagelives.com \
  --user StageLivesStressUser \
  --users 200 --spawn-rate 50 --run-time 2m --headless
```

### 예시 3: 로컬 서버 다양한 엔드포인트 테스트
```bash
# 터미널 1: 서버 실행 (Go 또는 Node.js 선택)
cd test_server && go run main.go
# 또는
cd node_loadtest && ./run.sh

# 터미널 2: Locust 웹 UI
cd python
locust -f locustfile.py --host=http://localhost:8080
# 브라우저에서 http://localhost:8089 접속
```

### 예시 4: Node.js vs Go 성능 비교
```bash
# 터미널 1: Node.js 서버
cd node_loadtest
./run.sh

# 터미널 2: 부하 테스트
cd go_loadtest
go run loadtest.go -url=http://localhost:8080/cpu -n=1000 -c=50

# 터미널 3: Go 서버로 전환 후 재테스트
cd test_server
go run main.go
```

---

## ⚠️ 주의사항

### 운영 서버 테스트 전 체크리스트
- [ ] 서버 소유자 승인
- [ ] 팀 공지 완료
- [ ] Off-peak 시간대 (새벽/주말)
- [ ] 모니터링 준비
- [ ] 백업 완료

### 권장 부하 수준

| 목적 | 동시 사용자 | 요청 수/시간 |
|------|------------|-------------|
| 기본 테스트 | 10-50 | 100-500 / 1-5분 |
| 성능 측정 | 50-100 | 1000-5000 / 5-10분 |
| 스트레스 | 100-300 | 무제한 / 2-5분 |
| 내구성 | 30-50 | 무제한 / 30분-1시간 |

**⚠️ 중요:** 항상 낮은 부하부터 시작하여 점진적으로 증가!

---

## 🛠 필수 설치

### Go (모든 도구 사용)
```bash
brew install go
```

### Node.js (node_loadtest/ 사용시)
```bash
brew install node
```

### Python + Locust (python/ 사용시)
```bash
brew install python3
pip3 install locust
```

---

## 🔍 도구 비교

### 테스트 서버 비교

| 특징 | Go (test_server) | Node.js (node_loadtest) |
|------|-----------------|------------------------|
| **언어** | Go | TypeScript/JavaScript |
| **성능** | 매우 빠름 | 빠름 |
| **메모리** | 매우 적음 | 적당 |
| **동시성** | 고루틴 (경량) | 이벤트 루프 |
| **타입** | 정적 타입 | TypeScript (정적) |
| **생태계** | Go 모듈 | npm (거대) |
| **적합** | 고성능 필요시 | 빠른 개발, 실시간 |

### 부하테스트 도구 비교

| 특징 | Go 부하테스트 | Python Locust |
|-----|--------------|--------------|
| **설치** | Go만 필요 | Python + Locust |
| **속도** | 매우 빠름 | 빠름 |
| **UI** | CLI만 | 웹 UI 제공 |
| **세션** | 기본 쿠키 | 완전한 세션 관리 |
| **복잡도** | 간단 | 복잡한 시나리오 가능 |
| **적합** | API 테스트 | 웹앱 전체 테스트 |

---

## 📚 상세 문서

- [test_server 문서](test_server/README.md) - Go 로컬 테스트 서버
- [node_loadtest 문서](node_loadtest/README.md) - Node.js 테스트 서버
- [go_loadtest 문서](go_loadtest/README.md) - Go 부하테스트
- [python 문서](python/README.md) - Python Locust

---

## 💡 트러블슈팅

### Go 관련
```bash
# Go 설치 확인
go version

# 빌드 후 실행 (더 빠름)
cd go_loadtest
go build -o loadtest loadtest.go
./loadtest -url=... -n=100 -c=10
```

### Python/Locust 관련
```bash
# 설치 확인
pip3 install locust
locust --version

# 포트 충돌시
locust -f stagelives_test.py --host=... --web-port=8090
```

### 연결 실패
```bash
# 연결 테스트
curl -v https://dev.stagelives.com

# DNS 확인
nslookup dev.stagelives.com
```

---

## 📖 참고 자료

- [Locust 공식 문서](https://docs.locust.io/)
- [Go HTTP 패키지](https://pkg.go.dev/net/http)
- [부하테스트 Best Practice](https://docs.locust.io/en/stable/writing-a-locustfile.html)

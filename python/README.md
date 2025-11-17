# Python Locust 부하테스트

고급 기능을 제공하는 Python 기반 부하테스트 도구

## 특징

- ✅ **웹 UI** - 실시간 그래프와 통계 (http://localhost:8089)
- ✅ **세션 관리** - 로그인 후 세션 유지
- ✅ **복잡한 시나리오** - 사용자 행동 패턴 시뮬레이션
- ✅ **분산 실행** - 여러 워커로 대규모 부하 생성

## 파일 구성

- `locustfile.py` - 로컬 테스트 서버용 (localhost:8080)
- `stagelives_test.py` - StageLives 서버용 (세션 기반)
- `run_test.sh` - 대화형 실행 스크립트

## 필수 설치

```bash
# Python 3.8+
brew install python3

# Locust
pip3 install locust

# 확인
locust --version
```

## 빠른 시작

### 방법 1: 대화형 스크립트 (권장)
```bash
./run_test.sh
```

선택 옵션:
1. 서버 선택 (dev/live/localhost)
2. 테스트 유형 (웹UI/기본/스트레스/헬스체크)
3. 부하 설정 입력

### 방법 2: 웹 UI 모드
```bash
# Dev 서버
locust -f stagelives_test.py --host=https://dev.stagelives.com

# 브라우저에서 http://localhost:8089 접속
# - Number of users: 50
# - Spawn rate: 10
# - Start 클릭
```

### 방법 3: Headless 모드 (자동 실행)
```bash
locust -f stagelives_test.py --host=https://dev.stagelives.com \
  --users 50 --spawn-rate 10 --run-time 60s --headless
```

## 사용자 클래스

### stagelives_test.py

#### 1. StageLivesUser (일반 사용자)
세션 기반 일반 사용자 시뮬레이션
- **대기 시간**: 1-3초
- **세션**: 로그인하여 세션 유지
- **사용법**:
```bash
locust -f stagelives_test.py --host=https://dev.stagelives.com \
  --user StageLivesUser --users 50 --spawn-rate 10
```

#### 2. StageLivesStressUser (스트레스 테스트)
고부하 스트레스 테스트용
- **대기 시간**: 0.1-0.5초 (매우 짧음)
- **세션**: 로그인하여 세션 유지
- **사용법**:
```bash
locust -f stagelives_test.py --host=https://dev.stagelives.com \
  --user StageLivesStressUser --users 200 --spawn-rate 50 --headless
```

#### 3. StageLivesAuthUser (인증 테스트)
로그인/로그아웃 반복 테스트
- **대기 시간**: 1-2초
- **세션**: 로그인/로그아웃 사이클 반복
- **사용법**:
```bash
locust -f stagelives_test.py --host=https://dev.stagelives.com \
  --user StageLivesAuthUser --users 30 --spawn-rate 5
```

### locustfile.py (로컬 서버용)

다양한 엔드포인트 테스트용 (test_server와 함께 사용)

```bash
# 로컬 서버 실행 (터미널 1)
cd ../test_server
go run main.go

# Locust 실행 (터미널 2)
locust -f locustfile.py --host=http://localhost:8080
```

## 세션 방식 동작

```python
class StageLivesUser(HttpUser):
    def on_start(self):
        """각 가상 사용자가 시작할 때 로그인"""
        response = self.client.post("/api/auth/login", json={
            "username": "testuser",
            "password": "testpassword123"
        })
        # 서버가 Set-Cookie로 세션 쿠키 전송
        # Locust가 자동으로 쿠키 저장 및 유지

    @task
    def api_call(self):
        # 이후 모든 요청에 세션 쿠키가 자동으로 포함됨
        self.client.get("/api/users")
```

## 테스트 시나리오 예시

### 1. 기본 성능 테스트
```bash
locust -f stagelives_test.py --host=https://dev.stagelives.com \
  --users 50 --spawn-rate 10 --run-time 5m --headless
```

### 2. 스트레스 테스트
```bash
locust -f stagelives_test.py --host=https://dev.stagelives.com \
  --user StageLivesStressUser \
  --users 200 --spawn-rate 50 --run-time 2m --headless
```

### 3. 스파이크 테스트 (급격한 증가)
```bash
locust -f stagelives_test.py --host=https://dev.stagelives.com \
  --users 500 --spawn-rate 100 --run-time 1m --headless
```

### 4. 내구성 테스트 (장시간)
```bash
locust -f stagelives_test.py --host=https://dev.stagelives.com \
  --users 30 --spawn-rate 5 --run-time 1h --headless
```

### 5. 결과 CSV로 저장
```bash
locust -f stagelives_test.py --host=https://dev.stagelives.com \
  --users 50 --spawn-rate 10 --run-time 5m \
  --headless --csv=results
# results_stats.csv, results_failures.csv 생성됨
```

## 웹 UI 사용법

1. **Locust 실행**
```bash
locust -f stagelives_test.py --host=https://dev.stagelives.com
```

2. **브라우저 접속**
- http://localhost:8089

3. **설정 입력**
- Number of users: 50 (동시 사용자 수)
- Spawn rate: 10 (초당 증가 사용자 수)

4. **Start 클릭**

5. **확인할 지표**
- **Statistics**: 요청별 통계 (응답시간, 실패율)
- **Charts**: 실시간 그래프
- **Response Times**: 50th/95th/99th percentile
- **RPS**: 초당 요청 수

## 고급 기능

### 분산 실행 (대규모 부하)
```bash
# 마스터 노드
locust -f stagelives_test.py --master --host=https://dev.stagelives.com

# 워커 노드 (다른 터미널들)
locust -f stagelives_test.py --worker --master-host=localhost
locust -f stagelives_test.py --worker --master-host=localhost
```

### 커스텀 헤더 추가
`stagelives_test.py` 수정:
```python
@task
def custom_request(self):
    self.client.get("/api/data", headers={
        "X-Custom-Header": "value",
        "Authorization": f"Bearer {self.token}"
    })
```

## 트러블슈팅

### Locust 설치 실패
```bash
pip3 install --upgrade pip
pip3 install locust
```

### 포트 충돌 (8089)
```bash
locust -f stagelives_test.py --host=... --web-port=8090
```

### Rate Limiting 걸림
- 사용자 수 줄이기
- 대기 시간 늘리기 (`wait_time = between(2, 5)`)
- API 키/토큰 사용

## 참고 자료
- Locust 공식 문서: https://docs.locust.io/
- 작성 가이드: https://docs.locust.io/en/stable/writing-a-locustfile.html

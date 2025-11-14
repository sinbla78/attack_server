# StageLives 부하테스트 가이드

## 빠른 시작

### 방법 1: 대화형 설정 스크립트 (권장)

```bash
./setup_load_test.sh
```

이 스크립트가 다음을 물어봅니다:
1. 대상 서버 선택 (live/dev/직접 입력)
2. API 엔드포인트 입력
3. HTTP 메서드 (GET/POST/PUT/DELETE)
4. 가중치 설정
5. 부하 설정 (사용자 수, 증가율 등)

완료되면 `stagelives_locustfile.py`가 자동 생성됩니다.

### 방법 2: 간단한 테스트 (Python 불필요)

```bash
./simple_load_test.sh
```

URL과 요청 수를 입력하면 바로 테스트가 실행됩니다.

## 사용 예시

### 예시 1: 대화형 설정

```bash
$ ./setup_load_test.sh

테스트할 서버를 선택하세요:
1) live.stagelives.com
2) dev.stagelives.com
3) 직접 입력
선택 (1-3): 2

선택된 서버: https://dev.stagelives.com

API 엔드포인트 설정
테스트할 엔드포인트를 입력하세요
엔드포인트 0: /api/users
  HTTP 메서드 (GET/POST/PUT/DELETE) [기본: GET]: GET
  가중치 (1-10) [기본: 5]: 8

엔드포인트 1: /api/products
  HTTP 메서드 [기본: GET]: GET
  가중치 [기본: 5]: 5

엔드포인트 2: /api/auth/login
  HTTP 메서드 [기본: GET]: POST
  가중치 [기본: 5]: 3
  JSON 데이터를 입력하세요: {"username": "test", "password": "test123"}

엔드포인트 3: (빈 줄 입력으로 종료)

동시 사용자 수 [기본: 10]: 20
사용자 증가율 (초당) [기본: 2]: 5
요청 간 대기 시간 (초) [기본: 1-3]: 1
요청 간 최대 대기 시간 (초) [기본: 3]: 2
```

### 예시 2: Locust 실행 (Python 설치 후)

```bash
# Python 설치
brew install python3

# Locust 설치
pip3 install locust

# 웹 UI 모드로 실행
locust -f stagelives_locustfile.py

# 브라우저에서 http://localhost:8089 접속
```

### 예시 3: Headless 모드 (자동 실행)

```bash
# 20명 사용자, 초당 5명 증가, 1분간 실행
locust -f stagelives_locustfile.py \
  --users 20 \
  --spawn-rate 5 \
  --run-time 60s \
  --headless

# 결과 CSV로 저장
locust -f stagelives_locustfile.py \
  --users 20 \
  --spawn-rate 5 \
  --run-time 60s \
  --headless \
  --csv=results
```

### 예시 4: 간단한 테스트

```bash
$ ./simple_load_test.sh

대상 URL: https://dev.stagelives.com/api/health
총 요청 수 [기본: 100]: 500
동시 실행 수 [기본: 10]: 20
```

## 주의사항

### 부하테스트 전 체크리스트

- [ ] 서버 소유자이거나 승인을 받았는가?
- [ ] 테스트 시간을 미리 공지했는가?
- [ ] 프로덕션 환경인 경우 off-peak 시간대인가?
- [ ] 모니터링 시스템이 준비되어 있는가?
- [ ] 백업이 준비되어 있는가?

### 권장 사항

1. **dev 서버로 먼저 테스트**: live 서버 전에 dev에서 테스트
2. **점진적 증가**: 낮은 부하부터 시작하여 서서히 증가
3. **모니터링**: 서버 CPU, 메모리, 응답시간 모니터링
4. **제한 설정**: 과도한 부하로 서비스 중단 방지

### 적절한 부하 수준

| 목적 | 사용자 수 | 증가율 | 지속 시간 |
|------|----------|--------|----------|
| 기본 테스트 | 10-50 | 2-5/초 | 1-5분 |
| 성능 측정 | 50-200 | 10/초 | 5-10분 |
| 스트레스 테스트 | 200-1000 | 20-50/초 | 5-15분 |
| 내구성 테스트 | 50-100 | 5/초 | 30분-1시간 |

## 결과 분석

### Locust 웹 UI에서 확인할 항목

1. **Response Time (ms)**: 응답 시간
   - 50th percentile: 중간값
   - 95th percentile: 95% 요청의 응답 시간
   - 99th percentile: 99% 요청의 응답 시간

2. **Requests per Second (RPS)**: 초당 처리 요청 수

3. **Failures**: 실패율
   - 5% 미만: 정상
   - 5-10%: 주의
   - 10% 이상: 문제

4. **Number of Users**: 동시 사용자 수 대비 성능

### 문제 진단

#### 응답 시간이 느림
- 서버 CPU/메모리 확인
- 데이터베이스 쿼리 최적화
- 캐싱 전략 검토

#### 에러율이 높음
- 로그에서 에러 메시지 확인
- Rate limiting 설정 확인
- 서버 리소스 부족 여부 확인

#### 처리량이 낮음
- 서버 스케일링 검토
- 병목 지점 찾기
- 로드 밸런서 설정 확인

## 트러블슈팅

### Python/Locust 설치 안 됨
```bash
# Python 설치
brew install python3

# Locust 설치
pip3 install locust

# 설치 확인
locust --version
```

### 대상 서버 연결 안 됨
```bash
# 연결 테스트
curl -v https://dev.stagelives.com

# DNS 확인
nslookup dev.stagelives.com

# SSL 인증서 확인
curl -vI https://dev.stagelives.com
```

### Rate Limiting 걸림
- 부하를 줄이기 (사용자 수 감소)
- 대기 시간 증가
- API 키/인증 토큰 사용

## 고급 사용법

### 인증이 필요한 API 테스트

`stagelives_locustfile.py` 수정:

```python
class StageLivesUser(HttpUser):
    def on_start(self):
        # 로그인하여 토큰 받기
        response = self.client.post("/api/auth/login", json={
            "username": "test",
            "password": "test123"
        })
        self.token = response.json()["token"]

    @task
    def authenticated_request(self):
        self.client.get("/api/protected", headers={
            "Authorization": f"Bearer {self.token}"
        })
```

### 여러 시나리오 테스트

```python
from locust import HttpUser, task, between, TaskSet

class BrowsingBehavior(TaskSet):
    @task(10)
    def view_products(self):
        self.client.get("/api/products")

    @task(3)
    def view_product_detail(self):
        product_id = random.randint(1, 100)
        self.client.get(f"/api/products/{product_id}")

    @task(1)
    def add_to_cart(self):
        self.client.post("/api/cart", json={"product_id": 1, "quantity": 1})

class WebsiteUser(HttpUser):
    tasks = [BrowsingBehavior]
    wait_time = between(1, 3)
```

## 참고 자료

- Locust 공식 문서: https://docs.locust.io/
- Apache Bench 가이드: https://httpd.apache.org/docs/2.4/programs/ab.html

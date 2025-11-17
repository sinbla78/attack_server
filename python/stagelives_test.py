"""
StageLives 부하테스트 스크립트 (세션 방식)
dev.stagelives.com 및 live.stagelives.com 테스트용
"""

from locust import HttpUser, task, between
import random
import json


class StageLivesUser(HttpUser):
    """
    StageLives 일반 사용자 시뮬레이션 (세션 기반)
    """
    wait_time = between(1, 3)  # 요청 간 1~3초 대기

    # 테스트할 서버를 환경변수나 커맨드라인으로 지정
    # locust -f stagelives_test.py --host=https://dev.stagelives.com
    # locust -f stagelives_test.py --host=https://live.stagelives.com

    def on_start(self):
        """사용자 시작 시 로그인하여 세션 획득"""
        # 로그인 시도
        login_payload = {
            "username": f"testuser{random.randint(1, 100)}",
            "password": "testpassword123"
        }

        # 로그인 엔드포인트 (실제 엔드포인트로 수정 필요)
        response = self.client.post(
            "/api/auth/login",
            json=login_payload,
            name="Login",
            catch_response=True
        )

        if response.status_code == 200:
            # 로그인 성공 - 세션 쿠키가 자동으로 저장됨
            response.success()
            # 필요시 응답에서 사용자 정보 저장
            try:
                data = response.json()
                self.user_id = data.get("user_id", random.randint(1, 1000))
            except:
                self.user_id = random.randint(1, 1000)
        else:
            # 로그인 실패시에도 테스트는 계속 진행
            response.failure(f"Login failed: {response.status_code}")
            self.user_id = random.randint(1, 1000)

    @task(10)
    def health_check(self):
        """헬스체크 (가장 높은 빈도)"""
        self.client.get("/api/health", name="Health Check")

    @task(5)
    def get_main_page(self):
        """메인 페이지 조회"""
        self.client.get("/", name="Main Page")

    @task(3)
    def get_api_endpoint(self):
        """일반 API 엔드포인트 조회"""
        # 실제 엔드포인트로 교체 필요
        endpoints = [
            "/api/users",
            "/api/products",
            "/api/content",
        ]
        endpoint = random.choice(endpoints)
        self.client.get(endpoint, name="API GET")


class StageLivesStressUser(HttpUser):
    """
    스트레스 테스트용 사용자 (짧은 대기시간, 세션 기반)
    """
    wait_time = between(0.1, 0.5)

    def on_start(self):
        """로그인하여 세션 획득"""
        login_payload = {
            "username": f"stressuser{random.randint(1, 100)}",
            "password": "testpassword123"
        }

        response = self.client.post(
            "/api/auth/login",
            json=login_payload,
            name="Login (Stress)",
            catch_response=True
        )

        if response.status_code == 200:
            response.success()
        else:
            response.failure(f"Login failed: {response.status_code}")

    @task(10)
    def rapid_health_check(self):
        """빠른 헬스체크 반복"""
        self.client.get("/api/health", name="Rapid Health Check")

    @task(5)
    def rapid_api_calls(self):
        """빠른 API 호출 (세션 쿠키 자동 포함)"""
        self.client.get("/api/users", name="Rapid API Call")


class StageLivesAuthUser(HttpUser):
    """
    인증 관련 테스트 사용자 (로그인/로그아웃 반복)
    """
    wait_time = between(1, 2)

    def on_start(self):
        """초기 세션 없이 시작"""
        self.logged_in = False

    @task(5)
    def login_logout_cycle(self):
        """로그인/로그아웃 사이클"""
        if not self.logged_in:
            # 로그인
            payload = {
                "username": f"testuser{random.randint(1, 100)}",
                "password": "testpassword123"
            }
            response = self.client.post(
                "/api/auth/login",
                json=payload,
                name="Login Attempt",
                catch_response=True
            )
            if response.status_code == 200:
                self.logged_in = True
                response.success()
        else:
            # 로그아웃
            response = self.client.post(
                "/api/auth/logout",
                name="Logout",
                catch_response=True
            )
            if response.status_code == 200:
                self.logged_in = False
                response.success()

    @task(2)
    def register_attempt(self):
        """회원가입 시도"""
        payload = {
            "username": f"newuser{random.randint(1, 10000)}",
            "email": f"test{random.randint(1, 10000)}@example.com",
            "password": "testpassword123"
        }
        self.client.post(
            "/api/auth/register",
            json=payload,
            name="Register Attempt",
            catch_response=True
        )


# 실행 예시:
#
# Dev 서버 테스트 (세션 기반):
#   locust -f stagelives_test.py --host=https://dev.stagelives.com
#
# Live 서버 테스트:
#   locust -f stagelives_test.py --host=https://live.stagelives.com
#
# Headless 모드 (100명 사용자, 60초):
#   locust -f stagelives_test.py --host=https://dev.stagelives.com --users 100 --spawn-rate 10 --run-time 60s --headless
#
# 특정 사용자 클래스만:
#   locust -f stagelives_test.py --host=https://dev.stagelives.com --user StageLivesUser
#
# 스트레스 테스트:
#   locust -f stagelives_test.py --host=https://dev.stagelives.com --user StageLivesStressUser --users 500 --spawn-rate 50 --headless
#
# 주의:
# - Locust HttpUser는 각 가상 사용자마다 독립적인 세션을 유지합니다
# - 로그인 시 받은 세션 쿠키는 해당 사용자의 모든 요청에 자동으로 포함됩니다
# - on_start()에서 로그인하면 이후 모든 요청이 인증된 상태로 전송됩니다

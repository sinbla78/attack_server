"""
Locust 부하테스트 스크립트
다양한 엔드포인트에 대한 부하 테스트를 수행합니다.
"""

from locust import HttpUser, task, between, TaskSet
import json
import random


class LoadTestTasks(TaskSet):
    """
    부하테스트 작업 정의
    """

    @task(10)
    def health_check(self):
        """빠른 응답 테스트 (가장 높은 비중)"""
        self.client.get("/health")

    @task(5)
    def cpu_intensive(self):
        """CPU 집약적 작업 테스트"""
        self.client.get("/cpu")

    @task(3)
    def slow_endpoint(self):
        """느린 응답 테스트"""
        self.client.get("/slow")

    @task(2)
    def memory_intensive(self):
        """메모리 집약적 작업 테스트"""
        self.client.get("/memory")

    @task(4)
    def json_post(self):
        """JSON POST 요청 테스트"""
        payload = {
            "user_id": random.randint(1, 10000),
            "action": random.choice(["create", "update", "delete"]),
            "data": {
                "timestamp": "2025-01-01T00:00:00Z",
                "value": random.random() * 1000,
                "metadata": {
                    "source": "locust",
                    "test": True
                }
            }
        }
        self.client.post(
            "/json",
            json=payload,
            headers={"Content-Type": "application/json"}
        )

    @task(2)
    def error_endpoint(self):
        """에러 발생 엔드포인트 테스트"""
        with self.client.get("/error", catch_response=True) as response:
            if response.status_code == 500:
                # 500 에러는 예상된 것이므로 실패로 처리하지 않음
                response.success()

    @task(1)
    def large_response(self):
        """대용량 응답 테스트"""
        self.client.get("/large")

    @task(1)
    def stats_check(self):
        """통계 확인"""
        self.client.get("/stats")


class WebsiteUser(HttpUser):
    """
    웹사이트 사용자 시뮬레이션
    """
    tasks = [LoadTestTasks]
    wait_time = between(0.5, 2.0)  # 요청 간 0.5~2초 대기

    def on_start(self):
        """사용자 시작 시 실행"""
        # 초기 연결 테스트
        self.client.get("/")


class StressTestUser(HttpUser):
    """
    스트레스 테스트용 사용자 (대기 시간 없음)
    """
    tasks = [LoadTestTasks]
    wait_time = between(0.1, 0.5)  # 짧은 대기 시간


class HealthCheckUser(HttpUser):
    """
    Health Check만 반복하는 사용자
    """
    wait_time = between(0.1, 0.3)

    @task
    def health_only(self):
        self.client.get("/health")


class CpuIntensiveUser(HttpUser):
    """
    CPU 집약적 작업만 수행하는 사용자
    """
    wait_time = between(0.5, 1.0)

    @task
    def cpu_only(self):
        self.client.get("/cpu")


# 실행 예시:
# 기본 부하테스트:
#   locust -f locustfile.py --host=http://localhost:8080
#
# 웹 UI 없이 실행 (100명 사용자, 초당 10명씩 증가):
#   locust -f locustfile.py --host=http://localhost:8080 --users 100 --spawn-rate 10 --headless --run-time 60s
#
# 특정 사용자 클래스만 실행:
#   locust -f locustfile.py --host=http://localhost:8080 --user WebsiteUser
#
# 스트레스 테스트:
#   locust -f locustfile.py --host=http://localhost:8080 --user StressTestUser --users 500 --spawn-rate 50 --headless

#!/bin/bash

# 대화형 부하테스트 설정 스크립트

echo "========================================="
echo "부하테스트 설정"
echo "========================================="
echo ""

# 1. 대상 서버 선택
echo "테스트할 서버를 선택하세요:"
echo "1) live.stagelives.com"
echo "2) dev.stagelives.com"
echo "3) 직접 입력"
read -p "선택 (1-3): " server_choice

case $server_choice in
    1)
        TARGET_HOST="https://live.stagelives.com"
        ;;
    2)
        TARGET_HOST="https://dev.stagelives.com"
        ;;
    3)
        read -p "서버 URL 입력 (예: https://example.com): " TARGET_HOST
        ;;
    *)
        echo "잘못된 선택입니다."
        exit 1
        ;;
esac

echo ""
echo "선택된 서버: $TARGET_HOST"
echo ""

# 2. API 엔드포인트 입력
echo "========================================="
echo "API 엔드포인트 설정"
echo "========================================="
echo "테스트할 엔드포인트를 입력하세요 (예: /api/users)"
echo "여러 개를 입력하려면 엔터를 누르고 계속 입력하세요."
echo "입력을 마치려면 빈 줄에서 엔터를 누르세요."
echo ""

ENDPOINTS=()
while true; do
    read -p "엔드포인트 ${#ENDPOINTS[@]}: " endpoint
    if [ -z "$endpoint" ]; then
        break
    fi

    # HTTP 메서드 선택
    echo "  HTTP 메서드 (GET/POST/PUT/DELETE) [기본: GET]: "
    read -p "  > " method
    method=${method:-GET}

    # 가중치 입력
    echo "  가중치 (1-10, 높을수록 더 자주 호출) [기본: 5]: "
    read -p "  > " weight
    weight=${weight:-5}

    # POST/PUT인 경우 JSON 데이터 입력
    json_data=""
    if [ "$method" = "POST" ] || [ "$method" = "PUT" ]; then
        echo "  JSON 데이터를 입력하세요 [선택사항, 엔터로 건너뛰기]: "
        read -p "  > " json_data
    fi

    ENDPOINTS+=("$endpoint|$method|$weight|$json_data")
    echo "  ✓ 추가됨: $method $endpoint (가중치: $weight)"
    echo ""
done

if [ ${#ENDPOINTS[@]} -eq 0 ]; then
    echo "엔드포인트가 입력되지 않았습니다. 기본값으로 / 를 사용합니다."
    ENDPOINTS+=("/|GET|10|")
fi

echo ""
echo "========================================="
echo "부하 설정"
echo "========================================="

read -p "동시 사용자 수 [기본: 10]: " users
users=${users:-10}

read -p "사용자 증가율 (초당) [기본: 2]: " spawn_rate
spawn_rate=${spawn_rate:-2}

read -p "요청 간 대기 시간 (초) [기본: 1-3]: " wait_min
wait_min=${wait_min:-1}
read -p "요청 간 최대 대기 시간 (초) [기본: 3]: " wait_max
wait_max=${wait_max:-3}

echo ""
echo "========================================="
echo "설정 확인"
echo "========================================="
echo "대상 서버: $TARGET_HOST"
echo "엔드포인트:"
for i in "${!ENDPOINTS[@]}"; do
    IFS='|' read -r endpoint method weight json_data <<< "${ENDPOINTS[$i]}"
    echo "  $((i+1)). $method $endpoint (가중치: $weight)"
    if [ -n "$json_data" ]; then
        echo "     데이터: $json_data"
    fi
done
echo "동시 사용자: $users"
echo "증가율: $spawn_rate/초"
echo "대기 시간: $wait_min-$wait_max초"
echo ""

read -p "이 설정으로 진행하시겠습니까? (y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "취소되었습니다."
    exit 0
fi

# Locust 파일 생성
cat > stagelives_locustfile.py << EOF
"""
StageLives 부하테스트 스크립트
자동 생성됨: $(date)
"""

from locust import HttpUser, task, between
import json

class StageLivesUser(HttpUser):
    """StageLives 사용자 시뮬레이션"""

    host = "$TARGET_HOST"
    wait_time = between($wait_min, $wait_max)

EOF

# 각 엔드포인트를 task로 추가
for i in "${!ENDPOINTS[@]}"; do
    IFS='|' read -r endpoint method weight json_data <<< "${ENDPOINTS[$i]}"

    cat >> stagelives_locustfile.py << EOF
    @task($weight)
    def endpoint_$i(self):
        """$method $endpoint"""
EOF

    if [ "$method" = "GET" ]; then
        cat >> stagelives_locustfile.py << EOF
        self.client.get("$endpoint")
EOF
    elif [ "$method" = "POST" ]; then
        if [ -n "$json_data" ]; then
            cat >> stagelives_locustfile.py << EOF
        self.client.post(
            "$endpoint",
            json=$json_data,
            headers={"Content-Type": "application/json"}
        )
EOF
        else
            cat >> stagelives_locustfile.py << EOF
        self.client.post("$endpoint")
EOF
        fi
    elif [ "$method" = "PUT" ]; then
        if [ -n "$json_data" ]; then
            cat >> stagelives_locustfile.py << EOF
        self.client.put(
            "$endpoint",
            json=$json_data,
            headers={"Content-Type": "application/json"}
        )
EOF
        else
            cat >> stagelives_locustfile.py << EOF
        self.client.put("$endpoint")
EOF
        fi
    elif [ "$method" = "DELETE" ]; then
        cat >> stagelives_locustfile.py << EOF
        self.client.delete("$endpoint")
EOF
    fi

    echo "" >> stagelives_locustfile.py
done

echo ""
echo "========================================="
echo "✅ 설정 완료!"
echo "========================================="
echo "생성된 파일: stagelives_locustfile.py"
echo ""
echo "다음 명령어로 테스트를 시작하세요:"
echo ""
echo "1. 웹 UI 모드:"
echo "   locust -f stagelives_locustfile.py"
echo "   브라우저에서 http://localhost:8089 접속"
echo ""
echo "2. Headless 모드 (자동 실행):"
echo "   locust -f stagelives_locustfile.py --users $users --spawn-rate $spawn_rate --run-time 60s --headless"
echo ""
echo "3. Python 없이 간단한 테스트:"
echo "   ./simple_load_test.sh"
echo ""

#!/bin/bash

# StageLives 부하테스트 실행 스크립트

echo "================================"
echo "StageLives 부하테스트"
echo "================================"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 서버 선택
echo "테스트할 서버를 선택하세요:"
echo "1) dev.stagelives.com (개발 서버)"
echo "2) live.stagelives.com (운영 서버)"
echo "3) localhost:8080 (로컬 테스트 서버)"
read -p "선택 (1-3): " server_choice

case $server_choice in
    1)
        HOST="https://dev.stagelives.com"
        echo -e "${GREEN}선택된 서버: dev.stagelives.com${NC}"
        ;;
    2)
        HOST="https://live.stagelives.com"
        echo -e "${YELLOW}경고: 운영 서버를 테스트합니다!${NC}"
        read -p "정말 진행하시겠습니까? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "테스트를 취소합니다."
            exit 0
        fi
        ;;
    3)
        HOST="http://localhost:8080"
        echo -e "${GREEN}선택된 서버: localhost:8080${NC}"
        ;;
    *)
        echo -e "${RED}잘못된 선택입니다.${NC}"
        exit 1
        ;;
esac

echo ""

# 테스트 유형 선택
echo "테스트 유형을 선택하세요:"
echo "1) 웹 UI 모드 (브라우저에서 조작)"
echo "2) 기본 부하테스트 (Headless)"
echo "3) 스트레스 테스트 (고부하)"
echo "4) 헬스체크만 집중 테스트"
read -p "선택 (1-4): " test_type

case $test_type in
    1)
        echo -e "${GREEN}웹 UI 모드로 실행합니다...${NC}"
        echo "브라우저에서 http://localhost:8089 를 열어주세요"
        locust -f stagelives_test.py --host=$HOST
        ;;
    2)
        read -p "동시 사용자 수 [기본: 50]: " users
        users=${users:-50}
        read -p "초당 증가율 [기본: 10]: " spawn_rate
        spawn_rate=${spawn_rate:-10}
        read -p "실행 시간(초) [기본: 60]: " run_time
        run_time=${run_time:-60}

        echo -e "${GREEN}기본 부하테스트 시작...${NC}"
        echo "설정: 사용자 $users명, 증가율 $spawn_rate/초, 시간 ${run_time}초"
        locust -f stagelives_test.py --host=$HOST \
            --user StageLivesUser \
            --users $users \
            --spawn-rate $spawn_rate \
            --run-time ${run_time}s \
            --headless
        ;;
    3)
        read -p "동시 사용자 수 [기본: 200]: " users
        users=${users:-200}
        read -p "초당 증가율 [기본: 50]: " spawn_rate
        spawn_rate=${spawn_rate:-50}
        read -p "실행 시간(초) [기본: 30]: " run_time
        run_time=${run_time:-30}

        echo -e "${YELLOW}스트레스 테스트 시작...${NC}"
        echo "설정: 사용자 $users명, 증가율 $spawn_rate/초, 시간 ${run_time}초"
        locust -f stagelives_test.py --host=$HOST \
            --user StageLivesStressUser \
            --users $users \
            --spawn-rate $spawn_rate \
            --run-time ${run_time}s \
            --headless
        ;;
    4)
        read -p "동시 사용자 수 [기본: 100]: " users
        users=${users:-100}
        read -p "실행 시간(초) [기본: 60]: " run_time
        run_time=${run_time:-60}

        echo -e "${GREEN}헬스체크 집중 테스트 시작...${NC}"
        echo "설정: 사용자 $users명, 시간 ${run_time}초"
        locust -f stagelives_test.py --host=$HOST \
            --user StageLivesUser \
            --users $users \
            --spawn-rate 20 \
            --run-time ${run_time}s \
            --headless
        ;;
    *)
        echo -e "${RED}잘못된 선택입니다.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}테스트가 완료되었습니다.${NC}"

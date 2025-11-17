#!/bin/bash

# Go 부하테스트 실행 스크립트

echo "================================"
echo "Go 부하테스트 도구"
echo "================================"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 대상 URL 입력
echo "테스트할 서버를 선택하세요:"
echo "1) dev.stagelives.com"
echo "2) live.stagelives.com (주의!)"
echo "3) localhost:8080"
echo "4) 직접 입력"
read -p "선택 (1-4): " server_choice

case $server_choice in
    1)
        read -p "엔드포인트 [기본: /api/health]: " endpoint
        endpoint=${endpoint:-/api/health}
        URL="https://dev.stagelives.com${endpoint}"
        echo -e "${GREEN}대상: dev.stagelives.com${endpoint}${NC}"
        ;;
    2)
        echo -e "${RED}경고: 운영 서버를 테스트합니다!${NC}"
        read -p "정말 진행하시겠습니까? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "테스트를 취소합니다."
            exit 0
        fi
        read -p "엔드포인트 [기본: /api/health]: " endpoint
        endpoint=${endpoint:-/api/health}
        URL="https://live.stagelives.com${endpoint}"
        echo -e "${YELLOW}대상: live.stagelives.com${endpoint}${NC}"
        ;;
    3)
        read -p "엔드포인트 [기본: /health]: " endpoint
        endpoint=${endpoint:-/health}
        URL="http://localhost:8080${endpoint}"
        echo -e "${GREEN}대상: localhost:8080${endpoint}${NC}"
        ;;
    4)
        read -p "전체 URL 입력: " URL
        echo -e "${BLUE}대상: ${URL}${NC}"
        ;;
    *)
        echo -e "${RED}잘못된 선택입니다.${NC}"
        exit 1
        ;;
esac

echo ""

# 테스트 모드 선택
echo "테스트 모드를 선택하세요:"
echo "1) 요청 수 기반 (N개의 요청 전송)"
echo "2) 시간 기반 (N초 동안 계속 요청)"
read -p "선택 (1-2): " mode_choice

if [ "$mode_choice" = "1" ]; then
    read -p "총 요청 수 [기본: 100]: " requests
    requests=${requests:-100}
    read -p "동시 사용자 수 [기본: 10]: " concurrency
    concurrency=${concurrency:-10}

    echo -e "${GREEN}요청 수 기반 테스트를 시작합니다...${NC}"
    echo "설정: 총 ${requests}개 요청, ${concurrency}명 동시 사용자"

    go run loadtest.go -url="$URL" -n=$requests -c=$concurrency

elif [ "$mode_choice" = "2" ]; then
    read -p "테스트 시간(초) [기본: 30]: " duration
    duration=${duration:-30}
    read -p "동시 사용자 수 [기본: 10]: " concurrency
    concurrency=${concurrency:-10}

    echo -e "${GREEN}시간 기반 테스트를 시작합니다...${NC}"
    echo "설정: ${duration}초 동안, ${concurrency}명 동시 사용자"

    go run loadtest.go -url="$URL" -n=0 -d=$duration -c=$concurrency

else
    echo -e "${RED}잘못된 선택입니다.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}테스트가 완료되었습니다!${NC}"

#!/bin/bash

# Python/Locust 없이 간단한 부하테스트

echo "========================================="
echo "간단한 부하테스트"
echo "========================================="
echo ""

read -p "대상 URL (예: https://dev.stagelives.com/api/test): " TARGET_URL
read -p "총 요청 수 [기본: 100]: " TOTAL_REQUESTS
TOTAL_REQUESTS=${TOTAL_REQUESTS:-100}
read -p "동시 실행 수 [기본: 10]: " CONCURRENT
CONCURRENT=${CONCURRENT:-10}

echo ""
echo "테스트 설정:"
echo "  대상: $TARGET_URL"
echo "  총 요청: $TOTAL_REQUESTS"
echo "  동시 실행: $CONCURRENT"
echo ""

read -p "시작하시겠습니까? (y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "취소되었습니다."
    exit 0
fi

echo ""
echo "테스트 시작..."
echo ""

# Apache Bench 사용 가능 여부 확인
if command -v ab &> /dev/null; then
    ab -n $TOTAL_REQUESTS -c $CONCURRENT "$TARGET_URL"
else
    echo "Apache Bench를 찾을 수 없습니다."
    echo "curl로 순차 테스트를 실행합니다..."
    echo ""

    START_TIME=$(date +%s)
    SUCCESS=0
    FAILED=0

    for i in $(seq 1 $TOTAL_REQUESTS); do
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET_URL")

        if [ "$HTTP_CODE" = "200" ]; then
            ((SUCCESS++))
        else
            ((FAILED++))
        fi

        if [ $((i % 10)) -eq 0 ]; then
            echo "진행: $i/$TOTAL_REQUESTS (성공: $SUCCESS, 실패: $FAILED)"
        fi
    done

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo ""
    echo "========================================="
    echo "결과"
    echo "========================================="
    echo "총 요청: $TOTAL_REQUESTS"
    echo "성공: $SUCCESS"
    echo "실패: $FAILED"
    echo "소요 시간: ${DURATION}초"
    if [ $DURATION -gt 0 ]; then
        echo "초당 요청: $(($TOTAL_REQUESTS / $DURATION)) req/s"
    fi
fi

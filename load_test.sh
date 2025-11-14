#!/bin/bash

# 간단한 부하테스트 스크립트
# 사용법: ./load_test.sh [엔드포인트] [요청수] [동시실행수]

HOST="http://localhost:8080"
ENDPOINT="${1:-/health}"
TOTAL_REQUESTS="${2:-1000}"
CONCURRENT="${3:-10}"

echo "========================================="
echo "부하테스트 시작"
echo "========================================="
echo "대상: $HOST$ENDPOINT"
echo "총 요청 수: $TOTAL_REQUESTS"
echo "동시 실행 수: $CONCURRENT"
echo "========================================="
echo ""

# Apache Bench 사용 (macOS에 기본 포함)
if command -v ab &> /dev/null; then
    echo "Apache Bench를 사용하여 테스트 중..."
    ab -n $TOTAL_REQUESTS -c $CONCURRENT "$HOST$ENDPOINT"
    echo ""
    echo "========================================="
    echo "서버 통계 확인"
    echo "========================================="
    curl -s "$HOST/stats" | python3 -m json.tool 2>/dev/null || curl -s "$HOST/stats"
else
    echo "Apache Bench (ab)를 찾을 수 없습니다."
    echo ""
    echo "간단한 curl 반복 테스트를 실행합니다..."
    echo ""

    START_TIME=$(date +%s)
    SUCCESS=0
    FAILED=0

    for i in $(seq 1 $TOTAL_REQUESTS); do
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HOST$ENDPOINT")

        if [ "$HTTP_CODE" = "200" ]; then
            ((SUCCESS++))
        else
            ((FAILED++))
        fi

        # 진행상황 표시
        if [ $((i % 100)) -eq 0 ]; then
            echo "진행: $i/$TOTAL_REQUESTS 요청 완료 (성공: $SUCCESS, 실패: $FAILED)"
        fi
    done

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo ""
    echo "========================================="
    echo "테스트 결과"
    echo "========================================="
    echo "총 요청: $TOTAL_REQUESTS"
    echo "성공: $SUCCESS"
    echo "실패: $FAILED"
    echo "소요 시간: ${DURATION}초"
    echo "초당 요청: $(($TOTAL_REQUESTS / $DURATION)) req/s"
    echo ""
    echo "========================================="
    echo "서버 통계"
    echo "========================================="
    curl -s "$HOST/stats"
    echo ""
fi

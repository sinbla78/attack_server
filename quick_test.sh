#!/bin/bash

# 빠른 테스트 스크립트 - 모든 엔드포인트 확인

HOST="http://localhost:8080"

echo "🧪 부하테스트 서버 기능 테스트"
echo "================================="
echo ""

# 서버 상태 확인
echo "1️⃣  서버 루트 확인..."
curl -s $HOST/ | head -n 3
echo ""
echo ""

# Health check
echo "2️⃣  Health Check 테스트..."
curl -s $HOST/health
echo ""
echo ""

# CPU intensive
echo "3️⃣  CPU 집약적 작업 테스트..."
time curl -s $HOST/cpu > /dev/null
echo ""

# Slow endpoint
echo "4️⃣  느린 응답 테스트..."
time curl -s $HOST/slow > /dev/null
echo ""

# Memory intensive
echo "5️⃣  메모리 집약적 작업 테스트..."
time curl -s $HOST/memory > /dev/null
echo ""

# JSON POST
echo "6️⃣  JSON POST 테스트..."
curl -s -X POST $HOST/json \
  -H "Content-Type: application/json" \
  -d '{"test": "data", "value": 123}'
echo ""
echo ""

# Error endpoint (여러 번 실행)
echo "7️⃣  에러 엔드포인트 테스트 (5회 실행)..."
for i in {1..5}; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $HOST/error)
    echo "  시도 $i: HTTP $HTTP_CODE"
done
echo ""

# Stats
echo "8️⃣  서버 통계..."
curl -s $HOST/stats
echo ""
echo ""

# Large response
echo "9️⃣  대용량 응답 테스트..."
RESPONSE_SIZE=$(curl -s $HOST/large | wc -c)
echo "  응답 크기: $RESPONSE_SIZE bytes"
echo ""

echo "================================="
echo "✅ 모든 테스트 완료!"
echo ""
echo "부하테스트를 실행하려면:"
echo "  ./load_test.sh /health 1000 10"
echo ""

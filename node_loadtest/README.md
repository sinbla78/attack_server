# Node.js Load Test Server

TypeScript + Express 기반의 고성능 부하 테스트 서버

## 특징

- **TypeScript** - 타입 안정성과 최신 JavaScript 기능
- **Express** - 빠르고 가벼운 웹 프레임워크
- **비동기 처리** - Node.js의 이벤트 루프 활용
- **실시간 통계** - 요청/에러/성능 메트릭 추적
- **다양한 시나리오** - CPU, 메모리, 지연, 에러 등

## 빠른 시작

### 1. 의존성 설치 및 실행
```bash
./run.sh
```

### 2. 또는 수동 실행
```bash
# 의존성 설치
npm install

# TypeScript 컴파일
npm run build

# 서버 시작
npm start
```

### 3. 개발 모드 (자동 재시작)
```bash
npm run dev
```

## API 엔드포인트

### GET /
- API 문서 및 사용 가이드
```bash
curl http://localhost:8080/
```

### GET /health
- 빠른 헬스체크
- 서버 상태, 타임스탬프, 업타임 반환
```bash
curl http://localhost:8080/health
```

### GET /cpu
- CPU 집약적 작업 (피보나치 계산)
- 응답 시간 측정
```bash
curl http://localhost:8080/cpu
```

### GET /slow
- 랜덤 지연 응답 (100-500ms)
- 네트워크 지연 시뮬레이션
```bash
curl http://localhost:8080/slow
```

### GET /memory
- 메모리 할당 테스트 (10MB)
- 메모리 사용량 반환
```bash
curl http://localhost:8080/memory
```

### POST /json
- JSON 데이터 파싱 테스트
- 받은 데이터 에코
```bash
curl -X POST http://localhost:8080/json \
  -H "Content-Type: application/json" \
  -d '{"name":"test","value":123}'
```

### GET /error
- 랜덤 에러 시뮬레이션 (30% 확률)
- 에러 처리 테스트용
```bash
curl http://localhost:8080/error
```

### GET /stats
- 서버 통계 및 메트릭
- 요청 수, 에러율, 메모리 사용량 등
```bash
curl http://localhost:8080/stats
```

### GET /large
- 대용량 응답 테스트 (1MB)
- 네트워크 대역폭 테스트
```bash
curl http://localhost:8080/large
```

### GET /async
- 비동기 작업 테스트
- Promise.all 활용
```bash
curl http://localhost:8080/async
```

### GET /stream
- 스트리밍 응답 테스트
- 청크 단위 전송
```bash
curl http://localhost:8080/stream
```

## 부하 테스트 예시

### Go 부하테스트 도구 사용
```bash
cd ../go_loadtest
go run loadtest.go -url=http://localhost:8080/cpu -n=100 -c=10
```

### Python Locust 사용
```bash
cd ../python
locust -f locustfile.py --host=http://localhost:8080
# 브라우저에서 http://localhost:8089 접속
```

### curl을 이용한 간단한 테스트
```bash
# 헬스체크
curl http://localhost:8080/health

# CPU 테스트
for i in {1..10}; do
  curl http://localhost:8080/cpu &
done
wait

# 통계 확인
curl http://localhost:8080/stats
```

## 프로젝트 구조

```
node_loadtest/
├── src/
│   └── server.ts         # 메인 서버 코드
├── dist/                 # 컴파일된 JavaScript
├── package.json          # 프로젝트 설정
├── tsconfig.json         # TypeScript 설정
├── run.sh               # 실행 스크립트
└── README.md            # 이 파일
```

## 개발

### TypeScript 컴파일
```bash
npm run build
```

### 개발 모드 (ts-node)
```bash
npm run dev
```

### 컴파일 와치 모드
```bash
npm run watch
```

## 환경 변수

```bash
# 포트 변경
PORT=3000 npm start

# 또는 .env 파일 생성
echo "PORT=3000" > .env
```

## 응답 예시

### /health
```json
{
  "status": "ok",
  "timestamp": "2024-11-15T10:30:00.000Z",
  "uptime": 123.456
}
```

### /stats
```json
{
  "uptime_seconds": 120,
  "total_requests": 1523,
  "requests_by_endpoint": {
    "/health": 500,
    "/cpu": 300,
    "/slow": 200
  },
  "error_count": 15,
  "error_rate": "0.98%",
  "requests_per_second": "12.69",
  "memory_usage": {
    "rss_mb": 45,
    "heap_used_mb": 12,
    "heap_total_mb": 20,
    "external_mb": 1
  },
  "process": {
    "pid": 12345,
    "node_version": "v20.10.0",
    "platform": "darwin",
    "uptime_seconds": 120
  }
}
```

## Node.js vs Go vs Python 비교

| 특징 | Node.js | Go | Python |
|------|---------|----|----|
| **언어** | TypeScript/JS | Go | Python |
| **성능** | 빠름 | 매우 빠름 | 보통 |
| **비동기** | 이벤트 루프 | 고루틴 | asyncio |
| **메모리** | 적당 | 매우 적음 | 많음 |
| **개발속도** | 빠름 | 보통 | 매우 빠름 |
| **생태계** | npm (거대) | 작지만 강력 | pip (거대) |
| **적합도** | API 서버, 실시간 | 고성능 서비스 | 스크립팅, ML |

## Node.js 서버의 장점

1. **비동기 I/O**: 동시에 많은 연결 처리
2. **빠른 개발**: TypeScript + Express로 신속한 개발
3. **풍부한 생태계**: npm 패키지 활용
4. **실시간 처리**: WebSocket, SSE 등 실시간 기능
5. **JSON 네이티브**: JSON 처리 최적화

## 트러블슈팅

### Node.js/npm 설치
```bash
# macOS
brew install node

# 버전 확인
node --version
npm --version
```

### 포트 충돌
```bash
# 8080 포트 사용 중인 프로세스 확인
lsof -i :8080

# 포트 변경
PORT=3000 npm start
```

### TypeScript 컴파일 에러
```bash
# node_modules 재설치
rm -rf node_modules package-lock.json
npm install

# TypeScript 재컴파일
npm run build
```

### 메모리 부족
```bash
# Node.js 메모리 제한 증가
NODE_OPTIONS="--max-old-space-size=4096" npm start
```

## 성능 팁

1. **클러스터 모드**: CPU 코어 수만큼 프로세스 실행
2. **Keep-Alive**: HTTP 연결 재사용
3. **Gzip 압축**: 응답 크기 감소
4. **캐싱**: Redis 등 활용
5. **로드 밸런싱**: Nginx, PM2 활용

## 추가 패키지

### PM2로 프로덕션 실행
```bash
npm install -g pm2
pm2 start dist/server.js --name loadtest -i max
pm2 monit
```

### 클러스터 모드
```bash
# 모든 CPU 코어 활용
pm2 start dist/server.js -i max
```

## 참고 자료

- [Express 공식 문서](https://expressjs.com/)
- [TypeScript 공식 문서](https://www.typescriptlang.org/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [PM2 문서](https://pm2.keymetrics.io/)

## 라이센스

MIT

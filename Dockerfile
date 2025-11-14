# 멀티 스테이지 빌드
FROM golang:1.21-alpine AS builder

# 작업 디렉토리 설정
WORKDIR /app

# Go 모듈 파일 복사
COPY go.mod ./

# 소스 코드 복사
COPY main.go ./

# 빌드 (정적 바이너리)
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server .

# 실행 스테이지
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# 빌더에서 실행 파일 복사
COPY --from=builder /app/server .

# 포트 노출
EXPOSE 8080

# 실행
CMD ["./server"]

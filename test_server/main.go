package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"runtime"
	"sync/atomic"
	"time"
)

var (
	requestCount uint64
	errorCount   uint64
)

type Response struct {
	Message   string      `json:"message"`
	Timestamp string      `json:"timestamp"`
	Data      interface{} `json:"data,omitempty"`
}

type StatsResponse struct {
	TotalRequests uint64  `json:"total_requests"`
	TotalErrors   uint64  `json:"total_errors"`
	Goroutines    int     `json:"goroutines"`
	MemoryUsageMB float64 `json:"memory_usage_mb"`
	Uptime        string  `json:"uptime"`
}

var startTime = time.Now()

// 빠른 응답 엔드포인트
func healthHandler(w http.ResponseWriter, r *http.Request) {
	atomic.AddUint64(&requestCount, 1)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Message:   "OK",
		Timestamp: time.Now().Format(time.RFC3339),
	})
}

// CPU 집약적 작업 시뮬레이션
func cpuIntensiveHandler(w http.ResponseWriter, r *http.Request) {
	atomic.AddUint64(&requestCount, 1)

	// CPU 부하를 위한 계산
	result := 0
	for i := 0; i < 1000000; i++ {
		result += i
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Message:   "CPU intensive task completed",
		Timestamp: time.Now().Format(time.RFC3339),
		Data:      map[string]int{"result": result},
	})
}

// 지연 응답 시뮬레이션
func slowHandler(w http.ResponseWriter, r *http.Request) {
	atomic.AddUint64(&requestCount, 1)

	// 100-500ms 랜덤 지연
	delay := time.Duration(100+rand.Intn(400)) * time.Millisecond
	time.Sleep(delay)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Message:   "Slow response completed",
		Timestamp: time.Now().Format(time.RFC3339),
		Data:      map[string]string{"delay": delay.String()},
	})
}

// 메모리 집약적 작업
func memoryIntensiveHandler(w http.ResponseWriter, r *http.Request) {
	atomic.AddUint64(&requestCount, 1)

	// 대량의 데이터 생성
	data := make([]byte, 10*1024*1024) // 10MB
	for i := range data {
		data[i] = byte(rand.Intn(256))
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Message:   "Memory intensive task completed",
		Timestamp: time.Now().Format(time.RFC3339),
		Data:      map[string]int{"bytes_allocated": len(data)},
	})
}

// JSON 파싱 테스트
func jsonHandler(w http.ResponseWriter, r *http.Request) {
	atomic.AddUint64(&requestCount, 1)

	if r.Method != http.MethodPost {
		atomic.AddUint64(&errorCount, 1)
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var payload map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		atomic.AddUint64(&errorCount, 1)
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Message:   "JSON parsed successfully",
		Timestamp: time.Now().Format(time.RFC3339),
		Data:      payload,
	})
}

// 에러 시뮬레이션 (30% 확률로 에러 반환)
func errorHandler(w http.ResponseWriter, r *http.Request) {
	atomic.AddUint64(&requestCount, 1)

	if rand.Float32() < 0.3 {
		atomic.AddUint64(&errorCount, 1)
		http.Error(w, "Random error occurred", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Message:   "Success",
		Timestamp: time.Now().Format(time.RFC3339),
	})
}

// 통계 정보 제공
func statsHandler(w http.ResponseWriter, r *http.Request) {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	stats := StatsResponse{
		TotalRequests: atomic.LoadUint64(&requestCount),
		TotalErrors:   atomic.LoadUint64(&errorCount),
		Goroutines:    runtime.NumGoroutine(),
		MemoryUsageMB: float64(m.Alloc) / 1024 / 1024,
		Uptime:        time.Since(startTime).String(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(stats)
}

// 대용량 응답 (1MB JSON)
func largeResponseHandler(w http.ResponseWriter, r *http.Request) {
	atomic.AddUint64(&requestCount, 1)

	// 대량의 데이터 생성
	items := make([]map[string]interface{}, 1000)
	for i := range items {
		items[i] = map[string]interface{}{
			"id":        i,
			"name":      fmt.Sprintf("Item %d", i),
			"value":     rand.Float64() * 1000,
			"timestamp": time.Now().Format(time.RFC3339),
			"data":      fmt.Sprintf("Data string %d with some padding to increase size", i),
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Message:   "Large response",
		Timestamp: time.Now().Format(time.RFC3339),
		Data:      items,
	})
}

func main() {
	rand.Seed(time.Now().UnixNano())

	// 라우트 설정
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/cpu", cpuIntensiveHandler)
	http.HandleFunc("/slow", slowHandler)
	http.HandleFunc("/memory", memoryIntensiveHandler)
	http.HandleFunc("/json", jsonHandler)
	http.HandleFunc("/error", errorHandler)
	http.HandleFunc("/stats", statsHandler)
	http.HandleFunc("/large", largeResponseHandler)

	// 기본 루트
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		atomic.AddUint64(&requestCount, 1)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(Response{
			Message:   "Load Test Server is running",
			Timestamp: time.Now().Format(time.RFC3339),
			Data: map[string]string{
				"version": "1.0.0",
				"endpoints": "/health, /cpu, /slow, /memory, /json, /error, /stats, /large",
			},
		})
	})

	port := ":8080"
	fmt.Printf("🚀 Load Test Server starting on port %s\n", port)
	fmt.Println("Available endpoints:")
	fmt.Println("  GET  /health  - Quick health check")
	fmt.Println("  GET  /cpu     - CPU intensive task")
	fmt.Println("  GET  /slow    - Slow response (100-500ms)")
	fmt.Println("  GET  /memory  - Memory intensive task")
	fmt.Println("  POST /json    - JSON parsing test")
	fmt.Println("  GET  /error   - Random error (30% failure rate)")
	fmt.Println("  GET  /stats   - Server statistics")
	fmt.Println("  GET  /large   - Large response (1MB JSON)")

	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal(err)
	}
}

package main

import (
	"crypto/tls"
	"flag"
	"fmt"
	"io"
	"net/http"
	"sync"
	"sync/atomic"
	"time"
)

// 통계 정보
type Stats struct {
	totalRequests   uint64
	successRequests uint64
	failedRequests  uint64
	totalDuration   int64 // 나노초
}

var stats Stats

// 부하테스트 설정
type Config struct {
	URL         string
	Concurrency int           // 동시 사용자 수
	Requests    int           // 총 요청 수
	Duration    time.Duration // 테스트 지속 시간
	Timeout     time.Duration // 요청 타임아웃
	Method      string        // HTTP 메서드
	KeepAlive   bool          // Keep-Alive 사용 여부
}

func main() {
	// 커맨드라인 플래그
	url := flag.String("url", "http://localhost:8080/health", "대상 URL")
	concurrency := flag.Int("c", 10, "동시 사용자 수")
	requests := flag.Int("n", 100, "총 요청 수 (0이면 duration만큼 실행)")
	duration := flag.Int("d", 10, "테스트 지속 시간(초) (n=0일 때만 사용)")
	timeout := flag.Int("t", 30, "요청 타임아웃(초)")
	method := flag.String("m", "GET", "HTTP 메서드")
	keepAlive := flag.Bool("k", true, "Keep-Alive 사용")

	flag.Parse()

	config := Config{
		URL:         *url,
		Concurrency: *concurrency,
		Requests:    *requests,
		Duration:    time.Duration(*duration) * time.Second,
		Timeout:     time.Duration(*timeout) * time.Second,
		Method:      *method,
		KeepAlive:   *keepAlive,
	}

	fmt.Println("🚀 Go 부하테스트 시작")
	fmt.Println("=====================================")
	fmt.Printf("대상 URL: %s\n", config.URL)
	fmt.Printf("HTTP 메서드: %s\n", config.Method)
	fmt.Printf("동시 사용자 수: %d\n", config.Concurrency)

	if config.Requests > 0 {
		fmt.Printf("총 요청 수: %d\n", config.Requests)
	} else {
		fmt.Printf("테스트 시간: %v\n", config.Duration)
	}

	fmt.Printf("타임아웃: %v\n", config.Timeout)
	fmt.Printf("Keep-Alive: %v\n", config.KeepAlive)
	fmt.Println("=====================================")

	runLoadTest(config)
}

func runLoadTest(config Config) {
	// HTTP 클라이언트 설정
	transport := &http.Transport{
		MaxIdleConns:        config.Concurrency,
		MaxIdleConnsPerHost: config.Concurrency,
		IdleConnTimeout:     90 * time.Second,
		DisableKeepAlives:   !config.KeepAlive,
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true, // 개발 환경용
		},
	}

	client := &http.Client{
		Transport: transport,
		Timeout:   config.Timeout,
	}

	var wg sync.WaitGroup
	startTime := time.Now()

	// 요청 수 기반 vs 시간 기반
	if config.Requests > 0 {
		// 요청 수 기반 테스트
		requestsPerWorker := config.Requests / config.Concurrency
		remainder := config.Requests % config.Concurrency

		for i := 0; i < config.Concurrency; i++ {
			workerRequests := requestsPerWorker
			if i < remainder {
				workerRequests++
			}

			wg.Add(1)
			go func(requests int) {
				defer wg.Done()
				for j := 0; j < requests; j++ {
					sendRequest(client, config)
				}
			}(workerRequests)
		}
	} else {
		// 시간 기반 테스트
		stopChan := make(chan struct{})

		// 타이머 설정
		go func() {
			time.Sleep(config.Duration)
			close(stopChan)
		}()

		for i := 0; i < config.Concurrency; i++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				for {
					select {
					case <-stopChan:
						return
					default:
						sendRequest(client, config)
					}
				}
			}()
		}
	}

	// 진행 상황 출력
	go printProgress()

	wg.Wait()
	elapsed := time.Since(startTime)

	// 최종 결과 출력
	printResults(elapsed)
}

func sendRequest(client *http.Client, config Config) {
	start := time.Now()

	req, err := http.NewRequest(config.Method, config.URL, nil)
	if err != nil {
		atomic.AddUint64(&stats.failedRequests, 1)
		return
	}

	resp, err := client.Do(req)
	if err != nil {
		atomic.AddUint64(&stats.failedRequests, 1)
		atomic.AddUint64(&stats.totalRequests, 1)
		return
	}
	defer resp.Body.Close()

	// 응답 body 읽기 (읽지 않으면 연결이 재사용되지 않음)
	io.Copy(io.Discard, resp.Body)

	duration := time.Since(start)
	atomic.AddInt64(&stats.totalDuration, duration.Nanoseconds())
	atomic.AddUint64(&stats.totalRequests, 1)

	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		atomic.AddUint64(&stats.successRequests, 1)
	} else {
		atomic.AddUint64(&stats.failedRequests, 1)
	}
}

func printProgress() {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	lastRequests := uint64(0)

	for range ticker.C {
		current := atomic.LoadUint64(&stats.totalRequests)
		rps := current - lastRequests
		lastRequests = current

		fmt.Printf("\r진행중... 총 요청: %d | 성공: %d | 실패: %d | RPS: %d",
			current,
			atomic.LoadUint64(&stats.successRequests),
			atomic.LoadUint64(&stats.failedRequests),
			rps,
		)

		if current > 0 && atomic.LoadUint64(&stats.failedRequests) == 0 &&
			atomic.LoadUint64(&stats.successRequests) == current {
			// 모든 요청 완료
			if lastRequests == current {
				return
			}
		}
	}
}

func printResults(elapsed time.Duration) {
	fmt.Println("\n\n=====================================")
	fmt.Println("📊 부하테스트 결과")
	fmt.Println("=====================================")

	total := atomic.LoadUint64(&stats.totalRequests)
	success := atomic.LoadUint64(&stats.successRequests)
	failed := atomic.LoadUint64(&stats.failedRequests)
	totalDuration := atomic.LoadInt64(&stats.totalDuration)

	fmt.Printf("총 요청 수: %d\n", total)
	fmt.Printf("성공: %d (%.2f%%)\n", success, float64(success)/float64(total)*100)
	fmt.Printf("실패: %d (%.2f%%)\n", failed, float64(failed)/float64(total)*100)
	fmt.Printf("총 소요 시간: %v\n", elapsed)

	if total > 0 {
		rps := float64(total) / elapsed.Seconds()
		avgDuration := time.Duration(totalDuration / int64(total))

		fmt.Printf("RPS (초당 요청 수): %.2f\n", rps)
		fmt.Printf("평균 응답 시간: %v\n", avgDuration)
		fmt.Printf("평균 처리량: %.2f req/sec\n", rps)
	}

	fmt.Println("=====================================")
}

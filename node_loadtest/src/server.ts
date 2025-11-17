import express, { Request, Response } from 'express';

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Stats tracking
interface Stats {
  totalRequests: number;
  requestsByEndpoint: { [key: string]: number };
  errors: number;
  startTime: Date;
}

const stats: Stats = {
  totalRequests: 0,
  requestsByEndpoint: {},
  errors: 0,
  startTime: new Date(),
};

// Middleware to track requests
app.use((req: Request, res: Response, next) => {
  stats.totalRequests++;
  const endpoint = req.path;
  stats.requestsByEndpoint[endpoint] = (stats.requestsByEndpoint[endpoint] || 0) + 1;
  next();
});

// Helper functions
const sleep = (ms: number): Promise<void> => new Promise(resolve => setTimeout(resolve, ms));

const fibonacci = (n: number): number => {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
};

const allocateMemory = (sizeMB: number): Buffer => {
  return Buffer.alloc(sizeMB * 1024 * 1024);
};

// Routes

/**
 * GET /health - Quick health check
 */
app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

/**
 * GET /cpu - CPU intensive operation
 */
app.get('/cpu', (req: Request, res: Response) => {
  const start = Date.now();
  const result = fibonacci(35); // CPU intensive
  const duration = Date.now() - start;

  res.json({
    result,
    duration_ms: duration,
    message: 'CPU intensive task completed',
  });
});

/**
 * GET /slow - Slow response with random delay
 */
app.get('/slow', async (req: Request, res: Response) => {
  const delay = Math.floor(Math.random() * 400) + 100; // 100-500ms
  await sleep(delay);

  res.json({
    message: 'Slow response completed',
    delay_ms: delay,
  });
});

/**
 * GET /memory - Memory intensive operation
 */
app.get('/memory', (req: Request, res: Response) => {
  try {
    const buffers: Buffer[] = [];

    // Allocate 10MB
    for (let i = 0; i < 10; i++) {
      buffers.push(allocateMemory(1));
    }

    const memUsage = process.memoryUsage();

    res.json({
      message: 'Memory allocated',
      allocated_mb: 10,
      memory_usage: {
        rss_mb: Math.round(memUsage.rss / 1024 / 1024),
        heap_used_mb: Math.round(memUsage.heapUsed / 1024 / 1024),
        heap_total_mb: Math.round(memUsage.heapTotal / 1024 / 1024),
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Memory allocation failed' });
  }
});

/**
 * POST /json - JSON parsing test
 */
app.post('/json', (req: Request, res: Response) => {
  const receivedData = req.body;

  res.json({
    message: 'JSON processed successfully',
    received_keys: Object.keys(receivedData).length,
    echo: receivedData,
  });
});

/**
 * GET /error - Random error simulation (30% chance)
 */
app.get('/error', (req: Request, res: Response) => {
  if (Math.random() < 0.3) {
    stats.errors++;
    res.status(500).json({
      error: 'Random error occurred',
      message: 'This is a simulated error',
    });
  } else {
    res.json({
      message: 'Request succeeded',
      status: 'ok',
    });
  }
});

/**
 * GET /stats - Server statistics
 */
app.get('/stats', (req: Request, res: Response) => {
  const uptime = Date.now() - stats.startTime.getTime();
  const memUsage = process.memoryUsage();

  res.json({
    uptime_seconds: Math.floor(uptime / 1000),
    total_requests: stats.totalRequests,
    requests_by_endpoint: stats.requestsByEndpoint,
    error_count: stats.errors,
    error_rate: stats.totalRequests > 0
      ? ((stats.errors / stats.totalRequests) * 100).toFixed(2) + '%'
      : '0%',
    requests_per_second: (stats.totalRequests / (uptime / 1000)).toFixed(2),
    memory_usage: {
      rss_mb: Math.round(memUsage.rss / 1024 / 1024),
      heap_used_mb: Math.round(memUsage.heapUsed / 1024 / 1024),
      heap_total_mb: Math.round(memUsage.heapTotal / 1024 / 1024),
      external_mb: Math.round(memUsage.external / 1024 / 1024),
    },
    process: {
      pid: process.pid,
      node_version: process.version,
      platform: process.platform,
      uptime_seconds: Math.floor(process.uptime()),
    },
  });
});

/**
 * GET /large - Large response (1MB)
 */
app.get('/large', (req: Request, res: Response) => {
  const data = 'x'.repeat(1024 * 1024); // 1MB of data

  res.json({
    message: 'Large response',
    size_bytes: data.length,
    size_mb: (data.length / 1024 / 1024).toFixed(2),
    data,
  });
});

/**
 * GET /async - Async operations test
 */
app.get('/async', async (req: Request, res: Response) => {
  const operations = Array.from({ length: 5 }, async (_, i) => {
    await sleep(Math.random() * 100);
    return `Operation ${i + 1} completed`;
  });

  const results = await Promise.all(operations);

  res.json({
    message: 'Async operations completed',
    results,
  });
});

/**
 * GET /stream - Streaming response test
 */
app.get('/stream', (req: Request, res: Response) => {
  res.setHeader('Content-Type', 'text/plain');
  res.setHeader('Transfer-Encoding', 'chunked');

  let count = 0;
  const interval = setInterval(() => {
    count++;
    res.write(`Chunk ${count}: ${new Date().toISOString()}\n`);

    if (count >= 10) {
      clearInterval(interval);
      res.end('Stream completed\n');
    }
  }, 100);
});

/**
 * GET / - Root endpoint with API documentation
 */
app.get('/', (req: Request, res: Response) => {
  res.json({
    message: 'Node.js Load Test Server',
    version: '1.0.0',
    endpoints: {
      'GET /health': 'Quick health check',
      'GET /cpu': 'CPU intensive operation (Fibonacci)',
      'GET /slow': 'Slow response with random delay (100-500ms)',
      'GET /memory': 'Memory intensive operation (10MB allocation)',
      'POST /json': 'JSON parsing test',
      'GET /error': 'Random error simulation (30% error rate)',
      'GET /stats': 'Server statistics and metrics',
      'GET /large': 'Large response test (1MB)',
      'GET /async': 'Async operations test',
      'GET /stream': 'Streaming response test',
    },
    usage: {
      example_curl: 'curl http://localhost:8080/health',
      loadtest: 'cd ../go_loadtest && go run loadtest.go -url=http://localhost:8080/cpu -n=100 -c=10',
    },
  });
});

// Error handling middleware
app.use((err: Error, req: Request, res: Response, next: any) => {
  console.error('Error:', err.message);
  stats.errors++;
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message,
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════╗
║   Node.js Load Test Server                   ║
║   TypeScript + Express                       ║
╚═══════════════════════════════════════════════╝

🚀 Server running on: http://localhost:${PORT}
📊 Stats endpoint: http://localhost:${PORT}/stats
🏥 Health check: http://localhost:${PORT}/health

Available endpoints:
  GET  /health   - Quick health check
  GET  /cpu      - CPU intensive (Fibonacci)
  GET  /slow     - Random delay (100-500ms)
  GET  /memory   - Memory allocation (10MB)
  POST /json     - JSON parsing test
  GET  /error    - Random errors (30% rate)
  GET  /stats    - Server statistics
  GET  /large    - Large response (1MB)
  GET  /async    - Async operations
  GET  /stream   - Streaming response
  GET  /         - API documentation

Press Ctrl+C to stop the server
  `);
});

export default app;

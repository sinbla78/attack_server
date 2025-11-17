#!/bin/bash

echo "========================================"
echo "  Node.js Load Test Server"
echo "  TypeScript + Express"
echo "========================================"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js is not installed"
    echo "Install Node.js: https://nodejs.org/"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ Error: npm is not installed"
    echo "Install npm: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js version: $(node --version)"
echo "✅ npm version: $(npm --version)"
echo ""

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo ""
fi

# Check if TypeScript compilation is needed
if [ ! -d "dist" ] || [ "src/server.ts" -nt "dist/server.js" ]; then
    echo "🔨 Compiling TypeScript..."
    npm run build
    echo ""
fi

# Start the server
echo "🚀 Starting server..."
echo ""
npm start

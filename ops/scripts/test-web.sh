#!/bin/bash

# Script to run web frontend tests with Jest
# This ensures consistent test execution across different environments

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WEB_DIR="$PROJECT_ROOT/packages/web"

echo "==================================="
echo "Task Manager - Web Frontend Tests"
echo "==================================="
echo ""

# Check if we're in the right directory
if [ ! -f "$WEB_DIR/package.json" ]; then
    echo "Error: package.json not found in $WEB_DIR"
    exit 1
fi

cd "$WEB_DIR"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"
echo ""

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
    echo ""
fi

# Run tests based on argument
case "${1:-test}" in
    test)
        echo "Running tests..."
        npm test
        ;;
    coverage)
        echo "Running tests with coverage..."
        npm run test:coverage
        ;;
    watch)
        echo "Running tests in watch mode..."
        npm run test:watch
        ;;
    *)
        echo "Unknown command: $1"
        echo "Usage: $0 [test|coverage|watch]"
        exit 1
        ;;
esac

echo ""
echo "Web tests completed!"

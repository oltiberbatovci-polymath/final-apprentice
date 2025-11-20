#!/bin/bash

##############################################################################
# Run API Checks Script
# Installs dependencies for the Node/Express API and runs build/test commands.
##############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
API_DIR="$PROJECT_ROOT/packages/api"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  Event Planner API - Build & Tests${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

if [ ! -f "$API_DIR/package.json" ]; then
    echo -e "${RED}✗ package.json not found in $API_DIR${NC}"
    exit 1
fi

cd "$API_DIR"

if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js is not installed${NC}"
    echo -e "${YELLOW}Please install Node.js 18+ from https://nodejs.org/${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}✗ npm is not available on PATH${NC}"
    exit 1
fi

echo -e "${YELLOW}Node.js version:${NC} $(node --version)"
echo -e "${YELLOW}npm version:${NC} $(npm --version)"
echo ""

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    npm install
    echo ""
fi

MODE="${1:-test}"

case "$MODE" in
    test)
        echo -e "${YELLOW}Running npm test...${NC}"
        npm test
        ;;
    build)
        echo -e "${YELLOW}Running npm run build...${NC}"
        npm run build
        ;;
    dev)
        echo -e "${YELLOW}Starting development server (Ctrl+C to exit)...${NC}"
        npm run dev
        ;;
    prisma:migrate)
        echo -e "${YELLOW}Running Prisma migrations...${NC}"
        npm run prisma:migrate
        ;;
    *)
        echo -e "${RED}Unknown mode: $MODE${NC}"
        echo ""
        echo -e "${BLUE}Usage:${NC}"
        echo -e "  $0 [test|build|dev|prisma:migrate]"
        exit 1
        ;;
esac

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ Command completed successfully!${NC}"
else
    echo -e "${RED}✗ Command failed${NC}"
fi

echo -e "${BLUE}=====================================${NC}"

exit $EXIT_CODE

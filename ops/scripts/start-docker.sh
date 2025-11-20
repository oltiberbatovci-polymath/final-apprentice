#!/bin/bash

##############################################################################
# Docker Startup Script
# This script builds and starts all Docker services for the Task Manager app
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project root (2 levels up from ops/scripts)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  Task Manager - Docker Startup${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check if Docker is installed
echo -e "${YELLOW}[1/6] Checking Docker installation...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    echo -e "${YELLOW}Please install Docker: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is installed${NC}"
echo ""

# Check if Docker Compose is installed
echo -e "${YELLOW}[2/6] Checking Docker Compose installation...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    echo -e "${YELLOW}Please install Docker Compose: https://docs.docker.com/compose/install/${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose is installed${NC}"
echo ""

# Check if Docker daemon is running
echo -e "${YELLOW}[3/6] Checking Docker daemon...${NC}"
if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker daemon is not running${NC}"
    echo -e "${YELLOW}Please start Docker Desktop or the Docker daemon${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker daemon is running${NC}"
echo ""

# Navigate to project root
cd "$PROJECT_ROOT"

# Check if docker-compose.yml exists
echo -e "${YELLOW}[4/6] Checking docker-compose.yml...${NC}"
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}✗ docker-compose.yml not found in $PROJECT_ROOT${NC}"
    exit 1
fi
echo -e "${GREEN}✓ docker-compose.yml found${NC}"
echo ""

# Stop any existing containers
echo -e "${YELLOW}[5/6] Stopping existing containers...${NC}"
if docker-compose ps -q 2>/dev/null | grep -q .; then
    echo -e "${CYAN}Stopping running containers...${NC}"
    docker-compose down
    echo -e "${GREEN}✓ Containers stopped${NC}"
else
    echo -e "${GREEN}✓ No containers to stop${NC}"
fi
echo ""

# Build and start services
echo -e "${YELLOW}[6/6] Building and starting services...${NC}"
echo -e "${CYAN}This may take a few minutes on first run...${NC}"
echo ""

docker-compose up --build -d

echo ""
echo -e "${GREEN}✓ Services started successfully!${NC}"
echo ""

# Wait for services to be healthy
echo -e "${CYAN}Waiting for services to become healthy...${NC}"
echo -n "  "

WAIT_TIME=0
MAX_WAIT=60

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    # Check if database is healthy
    DB_HEALTHY=$(docker-compose ps db 2>/dev/null | grep -c "Up (healthy)" || echo "0")
    
    if [ "$DB_HEALTHY" -eq "1" ]; then
        echo ""
        echo -e "${GREEN}✓ Database is healthy!${NC}"
        break
    fi
    
    echo -n "."
    sleep 2
    WAIT_TIME=$((WAIT_TIME + 2))
done

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    echo ""
    echo -e "${YELLOW}⚠ Database took longer than expected to start${NC}"
    echo -e "${YELLOW}  Services may still be initializing...${NC}"
fi

# Give API a bit more time to connect to DB
echo -e "${CYAN}Waiting for API to connect to database...${NC}"
sleep 5

echo ""
echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}Task Manager is starting up!${NC}"
echo ""
echo -e "${BLUE}Access points:${NC}"
echo -e "  Web UI:      ${GREEN}http://localhost:8080${NC}"
echo -e "  API:         ${GREEN}http://localhost:5000${NC}"
echo -e "  Health:      ${GREEN}http://localhost:5000/health${NC}"
echo -e "  Database:   ${GREEN}localhost:5432${NC}"
echo ""
echo -e "${YELLOW}Tip: Services might need another 10-30 seconds to fully initialize${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Wait ~30 seconds for full initialization"
echo -e "  2. Run health check:  ${CYAN}./ops/scripts/check-docker.sh${NC}"
echo -e "  3. Open browser:      ${CYAN}http://localhost:8080${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  View logs:      ${YELLOW}docker-compose logs -f${NC}"
echo -e "  View API logs:  ${YELLOW}docker-compose logs -f api${NC}"
echo -e "  View Web logs:  ${YELLOW}docker-compose logs -f web${NC}"
echo -e "  Check status:   ${YELLOW}docker-compose ps${NC}"
echo -e "  Restart:        ${YELLOW}docker-compose restart${NC}"
echo -e "  Stop:           ${YELLOW}docker-compose down${NC}"
echo -e "${BLUE}=====================================${NC}"

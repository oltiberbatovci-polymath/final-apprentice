#!/bin/bash

##############################################################################
# Docker Health Check Script
# This script checks if all Docker services are running properly
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root (2 levels up from ops/scripts)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  Task Manager - Docker Health Check${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check if Docker is installed
echo -e "${YELLOW}[1/7] Checking Docker installation...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is installed${NC}"
echo ""

# Check if Docker Compose is installed
echo -e "${YELLOW}[2/7] Checking Docker Compose installation...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose is installed${NC}"
echo ""

# Check if Docker daemon is running
echo -e "${YELLOW}[3/7] Checking Docker daemon...${NC}"
if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker daemon is not running${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker daemon is running${NC}"
echo ""

# Navigate to project root
cd "$PROJECT_ROOT"

# Check if docker-compose.yml exists
echo -e "${YELLOW}[4/7] Checking docker-compose.yml...${NC}"
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}✗ docker-compose.yml not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ docker-compose.yml found${NC}"
echo ""

# Check if services are running
echo -e "${YELLOW}[5/7] Checking running services...${NC}"
if ! docker-compose ps | grep -q "Up"; then
    echo -e "${RED}✗ No services are running${NC}"
    echo -e "${YELLOW}Run 'docker-compose up -d' to start services${NC}"
    exit 1
fi

# Display service status
echo -e "${GREEN}✓ Services are running:${NC}"
docker-compose ps
echo ""

# Check individual service health
echo -e "${YELLOW}[6/7] Checking service health...${NC}"

# Check database
echo -n "  - Database (PostgreSQL): "
if docker-compose ps db | grep -q "Up (healthy)"; then
    echo -e "${GREEN}✓ Healthy${NC}"
elif docker-compose ps db | grep -q "Up"; then
    echo -e "${YELLOW}⚠ Running but not healthy yet${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
fi

# Check API
echo -n "  - API (Flask): "
API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health 2>/dev/null || echo "000")
if [ "$API_HEALTH" = "200" ]; then
    echo -e "${GREEN}✓ Healthy (HTTP 200)${NC}"
else
    echo -e "${RED}✗ Unhealthy (HTTP $API_HEALTH)${NC}"
fi

# Check Web
echo -n "  - Web (Frontend): "
WEB_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null || echo "000")
if [ "$WEB_HEALTH" = "200" ]; then
    echo -e "${GREEN}✓ Healthy (HTTP 200)${NC}"
else
    echo -e "${RED}✗ Unhealthy (HTTP $WEB_HEALTH)${NC}"
fi
echo ""

# Test API endpoints
echo -e "${YELLOW}[7/7] Testing API endpoints...${NC}"

echo -n "  - GET /health: "
HEALTH_RESPONSE=$(curl -s http://localhost:5000/health 2>/dev/null || echo "{}")
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo -e "${GREEN}✓ Working${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

echo -n "  - GET /api/tasks: "
TASKS_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/tasks 2>/dev/null || echo "000")
if [ "$TASKS_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Working (HTTP 200)${NC}"
else
    echo -e "${RED}✗ Failed (HTTP $TASKS_CODE)${NC}"
fi

echo -n "  - POST /api/tasks: "
POST_RESPONSE=$(curl -s -X POST http://localhost:5000/api/tasks \
    -H "Content-Type: application/json" \
    -d '{"title":"Health Check Test","description":"Automated test","status":"pending"}' \
    2>/dev/null || echo "{}")
if echo "$POST_RESPONSE" | grep -q "Health Check Test"; then
    echo -e "${GREEN}✓ Working${NC}"
    # Extract task ID and delete it
    TASK_ID=$(echo "$POST_RESPONSE" | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
    if [ -n "$TASK_ID" ]; then
        curl -s -X DELETE "http://localhost:5000/api/tasks/$TASK_ID" > /dev/null 2>&1
    fi
else
    echo -e "${RED}✗ Failed${NC}"
fi

echo ""
echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}Health check complete!${NC}"
echo ""
echo -e "${BLUE}Access points:${NC}"
echo -e "  Web UI:      ${GREEN}http://localhost:8080${NC}"
echo -e "  API:         ${GREEN}http://localhost:5000${NC}"
echo -e "  Health:      ${GREEN}http://localhost:5000/health${NC}"
echo -e "  Database:   ${GREEN}localhost:5432${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  View logs:      ${YELLOW}docker-compose logs -f${NC}"
echo -e "  Restart:        ${YELLOW}docker-compose restart${NC}"
echo -e "  Stop:           ${YELLOW}docker-compose down${NC}"
echo -e "  Rebuild:        ${YELLOW}docker-compose up --build -d${NC}"
echo -e "${BLUE}=====================================${NC}"

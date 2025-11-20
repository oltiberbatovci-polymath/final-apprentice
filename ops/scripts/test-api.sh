#!/bin/bash

##############################################################################
# Run API Tests Script
# This script runs the API unit tests with various options
##############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# API directory (one level up from ops/scripts, then into packages/api)
API_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/packages/api"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  Task Manager API - Unit Tests${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -d "$API_DIR" ]; then
    echo -e "${RED}✗ API directory not found at $API_DIR${NC}"
    exit 1
fi

cd "$API_DIR"

# Check if python3 is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ python3 is not installed${NC}"
    echo -e "${YELLOW}Please install Python 3.8 or higher${NC}"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Failed to create virtual environment${NC}"
        echo -e "${YELLOW}Try: sudo apt-get install python3-venv${NC}"
        exit 1
    fi
    echo ""
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip to avoid issues
pip install --upgrade pip -q

# Check if pytest is installed in venv
if ! python -c "import pytest" 2>/dev/null; then
    echo -e "${YELLOW}Installing test dependencies in virtual environment...${NC}"
    pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Failed to install dependencies${NC}"
        deactivate
        exit 1
    fi
    echo ""
fi

# Parse command line arguments
MODE="${1:-basic}"

case "$MODE" in
    basic)
        echo -e "${YELLOW}Running basic tests...${NC}"
        python -m pytest tests/ -v
        ;;
    
    coverage)
        echo -e "${YELLOW}Running tests with coverage...${NC}"
        python -m pytest tests/ --cov=src --cov-report=term-missing -v
        ;;
    
    html)
        echo -e "${YELLOW}Running tests with HTML coverage report...${NC}"
        python -m pytest tests/ --cov=src --cov-report=html -v
        echo ""
        echo -e "${GREEN}✓ Coverage report generated in htmlcov/index.html${NC}"
        ;;
    
    quick)
        echo -e "${YELLOW}Running quick tests (no verbose)...${NC}"
        python -m pytest tests/
        ;;
    
    watch)
        echo -e "${YELLOW}Running tests in watch mode...${NC}"
        echo -e "${BLUE}Note: Install pytest-watch with: pip install pytest-watch${NC}"
        ptw tests/ -- -v
        ;;
    
    *)
        echo -e "${RED}Unknown mode: $MODE${NC}"
        echo ""
        echo -e "${BLUE}Usage:${NC}"
        echo -e "  $0 [mode]"
        echo ""
        echo -e "${BLUE}Available modes:${NC}"
        echo -e "  basic      - Run all tests with verbose output (default)"
        echo -e "  coverage   - Run tests with coverage report in terminal"
        echo -e "  html       - Run tests and generate HTML coverage report"
        echo -e "  quick      - Run tests without verbose output"
        echo -e "  watch      - Run tests in watch mode (requires pytest-watch)"
        echo ""
        deactivate
        exit 1
        ;;
esac

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
else
    echo -e "${RED}✗ Some tests failed${NC}"
fi

echo -e "${BLUE}=====================================${NC}"

# Deactivate virtual environment
deactivate

exit $EXIT_CODE

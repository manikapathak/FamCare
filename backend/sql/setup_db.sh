#!/bin/bash
# Quick database setup script for FamCARE

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}FamCARE Database Setup Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check which database to use
if [ "$1" == "postgres" ] || [ "$1" == "postgresql" ]; then
    echo -e "${GREEN}Setting up PostgreSQL database...${NC}"

    # Check if psql is installed
    if ! command -v psql &> /dev/null; then
        echo -e "${RED}Error: psql (PostgreSQL client) not found. Install PostgreSQL.${NC}"
        exit 1
    fi

    # Prompt for database connection details
    read -p "PostgreSQL host (default: localhost): " PG_HOST
    PG_HOST=${PG_HOST:-localhost}

    read -p "PostgreSQL port (default: 5432): " PG_PORT
    PG_PORT=${PG_PORT:-5432}

    read -p "PostgreSQL username (default: postgres): " PG_USER
    PG_USER=${PG_USER:-postgres}

    read -sp "PostgreSQL password: " PG_PASSWORD
    echo ""

    read -p "Database name (default: famcare_db): " DB_NAME
    DB_NAME=${DB_NAME:-famcare_db}

    # Set environment variables for psql
    export PGHOST=$PG_HOST
    export PGPORT=$PG_PORT
    export PGUSER=$PG_USER
    export PGPASSWORD=$PG_PASSWORD

    # Create database
    echo -e "${GREEN}Creating database: $DB_NAME${NC}"
    createdb $DB_NAME 2>/dev/null || echo -e "${BLUE}Database may already exist, continuing...${NC}"

    # Run schema
    echo -e "${GREEN}Running schema setup...${NC}"
    psql -h $PG_HOST -U $PG_USER -d $DB_NAME -f sql/schema_postgresql.sql

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PostgreSQL setup completed successfully!${NC}"
        echo -e "${BLUE}Update .env with:${NC}"
        echo -e "DATABASE_URL=postgresql://$PG_USER:password@$PG_HOST:$PG_PORT/$DB_NAME"
    else
        echo -e "${RED}✗ PostgreSQL setup failed!${NC}"
        exit 1
    fi

elif [ "$1" == "sqlite" ]; then
    echo -e "${GREEN}Setting up SQLite database...${NC}"

    # Check if sqlite3 is installed
    if ! command -v sqlite3 &> /dev/null; then
        echo -e "${RED}Error: sqlite3 not found. Install SQLite.${NC}"
        exit 1
    fi

    read -p "Database file path (default: famcare.db): " DB_FILE
    DB_FILE=${DB_FILE:-famcare.db}

    # Create and populate database
    echo -e "${GREEN}Creating database: $DB_FILE${NC}"
    sqlite3 $DB_FILE < sql/schema_sqlite.sql

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ SQLite setup completed successfully!${NC}"
        echo -e "${BLUE}Update .env with:${NC}"
        echo -e "DATABASE_URL=sqlite:///./$DB_FILE"
        echo -e "${BLUE}Verify with:${NC}"
        echo -e "sqlite3 $DB_FILE '.tables'"
    else
        echo -e "${RED}✗ SQLite setup failed!${NC}"
        exit 1
    fi

else
    echo -e "${BLUE}Usage: ./setup_db.sh [postgres|sqlite]${NC}"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  ./setup_db.sh postgres    # Setup PostgreSQL database"
    echo -e "  ./setup_db.sh sqlite      # Setup SQLite database (development)"
    echo ""
    exit 0
fi

echo ""
echo -e "${GREEN}Next steps:${NC}"
echo -e "1. Update .env with DATABASE_URL"
echo -e "2. Start backend: cd ../.. && uvicorn app.main:app --reload"
echo -e "3. Test API: curl http://localhost:8000/docs"
echo ""

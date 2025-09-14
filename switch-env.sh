#!/bin/bash

# Environment switcher script for Iris Vision
# Usage: ./switch-env.sh [local|production]

set -e

ENV_MODE=${1:-local}

if [[ "$ENV_MODE" != "local" && "$ENV_MODE" != "production" ]]; then
    echo "Usage: $0 [local|production]"
    echo "  local      - Switch to local development mode (localhost:3000)"
    echo "  production - Switch to production mode (irisvision.ai)"
    exit 1
fi

echo "Switching to $ENV_MODE mode..."

# Function to get Supabase credentials from backend .env
get_supabase_credentials() {
    if [[ -f backend/.env ]]; then
        SUPABASE_URL=$(grep "^SUPABASE_URL=" backend/.env | cut -d'=' -f2-)
        SUPABASE_ANON_KEY=$(grep "^SUPABASE_ANON_KEY=" backend/.env | cut -d'=' -f2-)
        KORTIX_ADMIN_API_KEY=$(grep "^KORTIX_ADMIN_API_KEY=" backend/.env | cut -d'=' -f2-)
    else
        SUPABASE_URL=""
        SUPABASE_ANON_KEY=""
        KORTIX_ADMIN_API_KEY=""
    fi
}

# Get Supabase credentials
get_supabase_credentials

# Frontend environment - preserve existing values, only update environment-specific ones
if [[ -f frontend/.env.local ]]; then
    # Backup existing file
    cp frontend/.env.local frontend/.env.local.backup
    
    # Update only environment-specific variables
    if [[ "$ENV_MODE" == "local" ]]; then
        # Update or add local environment variables
        if grep -q "^NEXT_PUBLIC_ENV_MODE=" frontend/.env.local; then
            sed -i.bak 's/^NEXT_PUBLIC_ENV_MODE=.*/NEXT_PUBLIC_ENV_MODE=local/' frontend/.env.local
        else
            echo "NEXT_PUBLIC_ENV_MODE=local" >> frontend/.env.local
        fi
        
        if grep -q "^NEXT_PUBLIC_URL=" frontend/.env.local; then
            sed -i.bak 's|^NEXT_PUBLIC_URL=.*|NEXT_PUBLIC_URL=http://localhost:3000|' frontend/.env.local
        else
            echo "NEXT_PUBLIC_URL=http://localhost:3000" >> frontend/.env.local
        fi
        
        if grep -q "^NEXT_PUBLIC_BACKEND_URL=" frontend/.env.local; then
            sed -i.bak 's|^NEXT_PUBLIC_BACKEND_URL=.*|NEXT_PUBLIC_BACKEND_URL=http://localhost:8000/api|' frontend/.env.local
        else
            echo "NEXT_PUBLIC_BACKEND_URL=http://localhost:8000/api" >> frontend/.env.local
        fi
        
        # Update Supabase credentials if they exist
        if [[ -n "$SUPABASE_URL" ]]; then
            if grep -q "^NEXT_PUBLIC_SUPABASE_URL=" frontend/.env.local; then
                sed -i.bak "s|^NEXT_PUBLIC_SUPABASE_URL=.*|NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL|" frontend/.env.local
            else
                echo "NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL" >> frontend/.env.local
            fi
        fi
        
        if [[ -n "$SUPABASE_ANON_KEY" ]]; then
            if grep -q "^NEXT_PUBLIC_SUPABASE_ANON_KEY=" frontend/.env.local; then
                sed -i.bak "s|^NEXT_PUBLIC_SUPABASE_ANON_KEY=.*|NEXT_PUBLIC_SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY|" frontend/.env.local
            else
                echo "NEXT_PUBLIC_SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> frontend/.env.local
            fi
        fi
        
        if [[ -n "$KORTIX_ADMIN_API_KEY" ]]; then
            if grep -q "^KORTIX_ADMIN_API_KEY=" frontend/.env.local; then
                sed -i.bak "s|^KORTIX_ADMIN_API_KEY=.*|KORTIX_ADMIN_API_KEY=$KORTIX_ADMIN_API_KEY|" frontend/.env.local
            else
                echo "KORTIX_ADMIN_API_KEY=$KORTIX_ADMIN_API_KEY" >> frontend/.env.local
            fi
        fi
        
        rm -f frontend/.env.local.bak
        echo "✓ Frontend configured for local development (localhost:3000)"
    else
        # Update or add production environment variables
        if grep -q "^NEXT_PUBLIC_ENV_MODE=" frontend/.env.local; then
            sed -i.bak 's/^NEXT_PUBLIC_ENV_MODE=.*/NEXT_PUBLIC_ENV_MODE=production/' frontend/.env.local
        else
            echo "NEXT_PUBLIC_ENV_MODE=production" >> frontend/.env.local
        fi
        
        if grep -q "^NEXT_PUBLIC_URL=" frontend/.env.local; then
            sed -i.bak 's|^NEXT_PUBLIC_URL=.*|NEXT_PUBLIC_URL=https://irisvision.ai|' frontend/.env.local
        else
            echo "NEXT_PUBLIC_URL=https://irisvision.ai" >> frontend/.env.local
        fi
        
        if grep -q "^NEXT_PUBLIC_BACKEND_URL=" frontend/.env.local; then
            sed -i.bak 's|^NEXT_PUBLIC_BACKEND_URL=.*|NEXT_PUBLIC_BACKEND_URL=https://irisvision.ai/api|' frontend/.env.local
        else
            echo "NEXT_PUBLIC_BACKEND_URL=https://irisvision.ai/api" >> frontend/.env.local
        fi
        
        # Update Supabase credentials if they exist
        if [[ -n "$SUPABASE_URL" ]]; then
            if grep -q "^NEXT_PUBLIC_SUPABASE_URL=" frontend/.env.local; then
                sed -i.bak "s|^NEXT_PUBLIC_SUPABASE_URL=.*|NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL|" frontend/.env.local
            else
                echo "NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL" >> frontend/.env.local
            fi
        fi
        
        if [[ -n "$SUPABASE_ANON_KEY" ]]; then
            if grep -q "^NEXT_PUBLIC_SUPABASE_ANON_KEY=" frontend/.env.local; then
                sed -i.bak "s|^NEXT_PUBLIC_SUPABASE_ANON_KEY=.*|NEXT_PUBLIC_SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY|" frontend/.env.local
            else
                echo "NEXT_PUBLIC_SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> frontend/.env.local
            fi
        fi
        
        if [[ -n "$KORTIX_ADMIN_API_KEY" ]]; then
            if grep -q "^KORTIX_ADMIN_API_KEY=" frontend/.env.local; then
                sed -i.bak "s|^KORTIX_ADMIN_API_KEY=.*|KORTIX_ADMIN_API_KEY=$KORTIX_ADMIN_API_KEY|" frontend/.env.local
            else
                echo "KORTIX_ADMIN_API_KEY=$KORTIX_ADMIN_API_KEY" >> frontend/.env.local
            fi
        fi
        
        rm -f frontend/.env.local.bak
        echo "✓ Frontend configured for production (irisvision.ai)"
    fi
else
    # Create new file from template if it doesn't exist
    if [[ "$ENV_MODE" == "local" ]]; then
        cp frontend/.env.local.example frontend/.env.local
        echo "✓ Frontend configured for local development (localhost:3000) - created from template"
    else
        cp frontend/.env.production.example frontend/.env.local
        echo "✓ Frontend configured for production (irisvision.ai) - created from template"
    fi
fi

# Backend environment
if [[ "$ENV_MODE" == "local" ]]; then
    # Update backend .env for local mode
    if [[ -f backend/.env ]]; then
        sed -i.bak 's/^ENV_MODE=.*/ENV_MODE=local/' backend/.env
        sed -i.bak 's|^WEBHOOK_BASE_URL=.*|WEBHOOK_BASE_URL=http://localhost:8000|' backend/.env
        sed -i.bak 's|^FRONTEND_URL=.*|FRONTEND_URL=http://localhost:3000|' backend/.env
        rm backend/.env.bak
        echo "✓ Backend configured for local development"
    fi
else
    # Update backend .env for production mode
    if [[ -f backend/.env ]]; then
        sed -i.bak 's/^ENV_MODE=.*/ENV_MODE=production/' backend/.env
        sed -i.bak 's|^WEBHOOK_BASE_URL=.*|WEBHOOK_BASE_URL=https://irisvision.ai|' backend/.env
        sed -i.bak 's|^FRONTEND_URL=.*|FRONTEND_URL=https://irisvision.ai|' backend/.env
        rm backend/.env.bak
        echo "✓ Backend configured for production"
    fi
fi

# Docker Compose configuration
if [[ "$ENV_MODE" == "local" ]]; then
    # Create local docker-compose file (no Caddy)
    cat > docker-compose.local.yml << 'EOF'
# Local Development Docker Compose
# This file excludes Caddy and configures services for local development

services:
  redis:
    image: redis:7-alpine
    container_name: irisvision-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
      - ./backend/services/docker/redis.conf:/usr/local/etc/redis/redis.conf:ro
    command: redis-server /usr/local/etc/redis/redis.conf --save 60 1 --loglevel warning
    networks:
      - irisvision-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

  backend:
    image: ghcr.io/suna-ai/suna-backend:latest
    platform: linux/amd64
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: irisvision-backend
    restart: unless-stopped
    ports:
      - "8000:8000"
    volumes:
      - ./backend/.env:/app/.env
    env_file:
      - ./backend/.env
    environment:
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=
      - REDIS_SSL=False
    networks:
      - irisvision-network
    depends_on:
      redis:
        condition: service_healthy
      worker:
        condition: service_started

  worker:
    image: ghcr.io/suna-ai/suna-backend:latest
    platform: linux/amd64
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: irisvision-worker
    restart: unless-stopped
    command: uv run dramatiq --skip-logging --processes 4 --threads 4 run_agent_background
    volumes:
      - ./backend/.env:/app/.env:ro
    env_file:
      - ./backend/.env
    environment:
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=
      - REDIS_SSL=False
    networks:
      - irisvision-network
    depends_on:
      redis:
        condition: service_healthy

  frontend:
    init: true
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        - NEXT_PUBLIC_URL=http://localhost:3000
        - NEXT_PUBLIC_APP_URL=http://localhost:3000
        - NEXT_PUBLIC_BACKEND_URL=http://localhost:8000/api
        - NEXT_PUBLIC_ENV_MODE=local
    container_name: irisvision-frontend
    restart: unless-stopped
    ports:
      - "3000:3000"
    # Load runtime environment variables (including Supabase) for the Next.js server
    env_file:
      - ./frontend/.env.local
    environment:
      - NODE_ENV=development
      - NEXT_PUBLIC_URL=http://localhost:3000
      - NEXT_PUBLIC_APP_URL=http://localhost:3000
      - NEXT_PUBLIC_BACKEND_URL=http://localhost:8000/api
      - NEXT_PUBLIC_ENV_MODE=local
    networks:
      - irisvision-network
    depends_on:
      - backend

networks:
  irisvision-network:
    driver: bridge

volumes:
  redis_data:
EOF
    echo "✓ Docker Compose configured for local development (Caddy disabled)"
else
    # Remove local override to use production config
    rm -f docker-compose.local.yml
    echo "✓ Docker Compose configured for production (Caddy enabled)"
fi

echo ""
echo "🎉 Successfully switched to $ENV_MODE mode!"
echo ""
if [[ "$ENV_MODE" == "local" ]]; then
    echo "To start local development:"
    echo "  Frontend: cd frontend && npm run dev:3000"
    echo "  Backend:  cd backend && docker-compose up"
    echo ""
    echo "Or use Docker Compose for local development (no Caddy):"
    echo "  docker-compose -f docker-compose.local.yml up"
else
    echo "To start production deployment:"
    echo "  docker-compose up"
fi
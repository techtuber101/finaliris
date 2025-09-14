#!/bin/bash

# Quick start script for Iris Vision development
# This script sets up the environment and starts the development servers

set -e

echo "🚀 Starting Iris Vision Development Environment"
echo ""

# Check if we're in the right directory
if [[ ! -f "switch-env.sh" ]]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Switch to local mode
echo "📝 Configuring for local development..."
./switch-env.sh local

echo ""
echo "🎯 Choose your development setup:"
echo "1) Full Docker Compose (recommended)"
echo "2) Mixed: Docker backend + Local frontend"
echo "3) Local frontend only (backend must be running separately)"
echo ""

read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        echo "🐳 Starting full Docker Compose setup..."
        echo "   Frontend: http://localhost:3000"
        echo "   Backend:  http://localhost:8000"
        echo ""
        docker-compose -f docker-compose.yaml -f docker-compose.local.yml up
        ;;
    2)
        echo "🔀 Starting mixed development setup..."
        echo "   Backend: Docker Compose"
        echo "   Frontend: Local development server"
        echo ""
        echo "Starting backend in background..."
        docker-compose -f docker-compose.yaml -f docker-compose.local.yml up backend redis worker &
        
        echo "Waiting for backend to be ready..."
        sleep 10
        
        echo "Starting frontend development server..."
        cd frontend
        npm run dev:3000
        ;;
    3)
        echo "💻 Starting frontend development server only..."
        echo "   Make sure backend is running on http://localhost:8000"
        echo ""
        cd frontend
        npm run dev:3000
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac

#!/bin/bash

# ComfyUI Docker Management Script
# Usage: ./setup.sh [command]

# Get host IP
HOST_IP=$(hostname -I | awk '{print $1}')

# Function to initialize the setup
init() {
    echo "Initializing ComfyUI Docker setup..."
    
    # Create directories
    mkdir -p models output custom_nodes workflows traefik/config
    
    # Create traefik config file if it doesn't exist
    if [ ! -f "traefik/config/hosts.toml" ]; then
        cat > "traefik/config/hosts.toml" << 'EOF'
[http]
  [http.middlewares]
    [http.middlewares.compress.compress]
EOF
        echo "Created Traefik config file"
    fi
    
    # Check if hosts file entry exists
    if ! grep -q "comfyui.local" /etc/hosts; then
        echo "Adding comfyui.local to /etc/hosts (requires sudo)..."
        echo "127.0.0.1 comfyui.local" | sudo tee -a /etc/hosts
    else
        echo "comfyui.local already exists in /etc/hosts"
    fi
    
    # Make sure we have a Docker network for Traefik
    if ! docker network ls | grep -q comfyui-network; then
        docker network create comfyui-network
        echo "Created Docker network: comfyui-network"
    fi
    
    echo "Initialization complete!"
    echo ""
    echo "Now you can run:"
    echo "  ./setup.sh local     # to start ComfyUI in local-only mode"
    echo "  ./setup.sh wan       # to start ComfyUI in WAN-accessible mode"
    echo "  ./setup.sh direct    # to start ComfyUI without Traefik (direct port)"
}

# Function to start ComfyUI in local mode
start_local() {
    echo "Starting ComfyUI in local-only mode..."
    
    # Stop other modes if running
    docker compose -f wan-compose.yml down 2>/dev/null || true
    docker compose -f docker-compose-simple.yml down 2>/dev/null || true
    
    # Start local mode
    docker compose -f local-compose.yml down 2>/dev/null || true
    docker compose -f local-compose.yml up -d
    
    echo "ComfyUI is now running in local-only mode"
    echo "Access at: http://comfyui.local"
}

# Function to start ComfyUI in WAN mode
start_wan() {
    echo "Starting ComfyUI in WAN-accessible mode..."
    
    # Stop other modes if running
    docker compose -f local-compose.yml down 2>/dev/null || true
    docker compose -f docker-compose-simple.yml down 2>/dev/null || true
    
    # Start WAN mode
    docker compose -f wan-compose.yml down 2>/dev/null || true
    docker compose -f wan-compose.yml up -d
    
    echo "ComfyUI is now running in WAN-accessible mode"
    echo "Access locally at: http://comfyui.local"
    echo "Access from other devices on your network at: http://$HOST_IP"
}

# Function to start ComfyUI in direct mode (without Traefik)
start_direct() {
    echo "Starting ComfyUI in direct port mode..."
    
    # Create direct compose file if it doesn't exist
    if [ ! -f "docker-compose-simple.yml" ]; then
        cat > "docker-compose-simple.yml" << EOF
version: '3.8'

services:
  comfyui:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: comfyui
    restart: always
    ports:
      - "8188:8188"
    volumes:
      - ./models:/app/ComfyUI/models
      - ./output:/app/ComfyUI/output
      - ./custom_nodes:/app/ComfyUI/custom_nodes
      - ./workflows:/app/ComfyUI/workflows
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
EOF
        echo "Created direct compose file"
    fi
    
    # Stop other modes if running
    docker compose -f local-compose.yml down 2>/dev/null || true
    docker compose -f wan-compose.yml down 2>/dev/null || true
    
    # Start direct mode
    docker compose -f docker-compose-simple.yml down 2>/dev/null || true
    docker compose -f docker-compose-simple.yml up -d
    
    echo "ComfyUI is now running in direct port mode"
    echo "Access at: http://localhost:8188"
    echo "From other devices on your network: http://$HOST_IP:8188"
}

# Function to check status
status() {
    local_running=false
    wan_running=false
    direct_running=false
    
    if docker ps | grep -q comfyui-local; then
        local_running=true
    fi
    
    if docker ps | grep -q comfyui-wan; then
        wan_running=true
    fi
    
    if docker ps | grep -q comfyui$; then
        direct_running=true
    fi
    
    if [ "$local_running" = true ]; then
        echo "ComfyUI LOCAL mode is RUNNING"
        echo "Access at: http://comfyui.local"
    fi
    
    if [ "$wan_running" = true ]; then
        echo "ComfyUI WAN mode is RUNNING"
        echo "Access locally at: http://comfyui.local"
        echo "Access from other devices at: http://$HOST_IP"
    fi
    
    if [ "$direct_running" = true ]; then
        echo "ComfyUI DIRECT mode is RUNNING"
        echo "Access at: http://localhost:8188"
        echo "From other devices at: http://$HOST_IP:8188"
    fi
    
    if [ "$local_running" = false ] && [ "$wan_running" = false ] && [ "$direct_running" = false ]; then
        echo "No ComfyUI instances are running."
    fi
}

# Function to stop all ComfyUI instances
stop() {
    echo "Stopping all ComfyUI instances..."
    docker compose -f local-compose.yml down 2>/dev/null || true
    docker compose -f wan-compose.yml down 2>/dev/null || true
    docker compose -f docker-compose-simple.yml down 2>/dev/null || true
    echo "All ComfyUI instances stopped."
}

# Function to update ComfyUI
update() {
    echo "Updating ComfyUI..."
    docker build -t comfyui:latest .
    echo "Update complete. Restart your containers to apply changes:"
    echo "  ./setup.sh local     # for local mode"
    echo "  ./setup.sh wan       # for WAN mode" 
    echo "  ./setup.sh direct    # for direct port mode"
}

# Main script execution
case "$1" in
    init)
        init
        ;;
    local)
        start_local
        ;;
    wan)
        start_wan
        ;;
    direct)
        start_direct
        ;;
    status)
        status
        ;;
    stop)
        stop
        ;;
    update)
        update
        ;;
    *)
        echo "ComfyUI Docker Management Script"
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  init      Initialize the ComfyUI Docker setup"
        echo "  local     Start ComfyUI in local-only mode (accessible only at comfyui.local)"
        echo "  wan       Start ComfyUI in WAN-accessible mode (accessible from other devices)"
        echo "  direct    Start ComfyUI in direct port mode (http://localhost:8188)"
        echo "  status    Check the status of ComfyUI instances"
        echo "  stop      Stop all ComfyUI instances"
        echo "  update    Rebuild ComfyUI container to get the latest version"
        exit 1
        ;;
esac

exit 0
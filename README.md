# ComfyUI Docker Setup

Simple Docker setup for running ComfyUI with automatic GPU support. Run locally or make accessible on your network.

## Requirements

- Docker and Docker Compose
- NVIDIA GPU with drivers installed
- NVIDIA Container Toolkit

## Quick Start

```bash
# Clone the repository
git clone https://github.com/username/comfyui-docker.git
cd comfyui-docker

# Make the setup script executable
chmod +x setup.sh

# Initialize the setup
./setup.sh init

# Start ComfyUI in local-only mode
./setup.sh local
```

Access ComfyUI at: http://comfyui.local

## Features

- Run ComfyUI with proper GPU support
- Custom domain name (comfyui.local)
- Network access mode for phones and other devices
- Persistent storage for models and outputs
- Automatic container restart on boot
- Direct port mode fallback option

## Operating Modes

This setup offers three different ways to run ComfyUI:

1. **Local mode** (`./setup.sh local`)

   - Accessible only at http://comfyui.local from your computer
   - Uses Traefik with local-only port binding

2. **WAN mode** (`./setup.sh wan`)

   - Accessible at http://comfyui.local from your computer
   - Accessible at http://YOUR-IP-ADDRESS from other devices on your network
   - Uses Traefik for domain routing

3. **Direct mode** (`./setup.sh direct`)
   - Accessible at http://localhost:8188 from your computer
   - Accessible at http://YOUR-IP-ADDRESS:8188 from other devices on your network
   - Doesn't use Traefik - direct port exposure (fallback option)

## Basic Usage

```bash
# Local-only mode (only accessible from your computer)
./setup.sh local

# Network-accessible mode (accessible from other devices)
./setup.sh wan

# Direct port mode (fallback option)
./setup.sh direct

# Check the status of ComfyUI
./setup.sh status

# Stop all containers
./setup.sh stop

# Update ComfyUI
./setup.sh update
```

## Adding Models

1. Place your Stable Diffusion models in the `models/checkpoints` directory
2. Place VAE files in the `models/vae` directory
3. Place LoRA files in the `models/loras` directory

## Directory Structure

```
📂 comfyui-docker/
├── 📄 Dockerfile
├── 📄 local-compose.yml
├── 📄 wan-compose.yml
├── 📄 docker-compose-simple.yml (created automatically)
├── 📄 setup.sh
├── 📂 models/
├── 📂 output/
├── 📂 custom_nodes/
├── 📂 workflows/
└── 📂 traefik/
    └── 📂 config/
        └── 📄 hosts.toml
```

## Troubleshooting

If you encounter issues with local or WAN modes:

1. Try the direct mode as a fallback:

   ```bash
   ./setup.sh direct
   ```

2. Check the container logs:

   ```bash
   docker logs comfyui-local
   docker logs traefik-local
   ```

3. Make sure the comfyui.local entry exists in your hosts file:

   ```bash
   cat /etc/hosts | grep comfyui
   ```

4. Ensure the Docker network is created:

   ```bash
   docker network ls | grep comfyui-network
   ```

5. Verify all permissions are correct:
   ```bash
   ls -la models output custom_nodes workflows
   ```

## License

MIT

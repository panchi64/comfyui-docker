FROM nvidia/cuda:12.8.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    python3-pip \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git
WORKDIR /app/ComfyUI

# Install PyTorch with CUDA support
RUN pip3 install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu128

# Install ComfyUI dependencies
RUN pip3 install -r requirements.txt

# Create necessary directories with permissive permissions
RUN mkdir -p /app/ComfyUI/output && chmod 777 /app/ComfyUI/output
RUN mkdir -p /app/ComfyUI/models && chmod 777 /app/ComfyUI/models
RUN mkdir -p /app/ComfyUI/custom_nodes && chmod 777 /app/ComfyUI/custom_nodes
RUN mkdir -p /app/ComfyUI/workflows && chmod 777 /app/ComfyUI/workflows
RUN mkdir -p /app/ComfyUI/user && chmod 777 /app/ComfyUI/user

# Expose port
EXPOSE 8188

# Command to run ComfyUI
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--output-directory", "/app/ComfyUI/output"]
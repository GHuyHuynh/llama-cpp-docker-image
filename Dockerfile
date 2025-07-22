FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
   build-essential \
   cmake \
   curl \
   libcurl4-openssl-dev \
   python3 \
   python3-pip \
   git \
   wget \
   && rm -rf /var/lib/apt/lists/*

# Install Python dependencies for model download
RUN pip3 install huggingface_hub hf_transfer

# Build llama.cpp with CUDA support
RUN git clone https://github.com/ggml-org/llama.cpp && \
   cmake llama.cpp -B llama.cpp/build \
   -DBUILD_SHARED_LIBS=OFF -DGGML_CUDA=ON -DLLAMA_CURL=ON && \
   cmake --build llama.cpp/build --config Release -j \
   --clean-first --target llama-quantize llama-cli llama-gguf-split llama-mtmd-cli && \
   cp llama.cpp/build/bin/llama-* llama.cpp/

# Create app directory
WORKDIR /app

# Copy startup script
COPY download_and_run.sh .
RUN chmod +x download_and_run.sh

# Expose port
EXPOSE 8080

# Health check - llama.cpp will respond on port 8080 when ready
HEALTHCHECK --interval=30s --timeout=10s --start-period=600s --retries=3 \
   CMD curl -f http://localhost:8080/ || exit 1

# Start the application
CMD ["./download_and_run.sh"]
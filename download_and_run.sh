#!/bin/bash

set -e  # Exit on any error

echo "Starting Kimi K2 deployment..."

# Create model directory
MODEL_DIR="/tmp/model"
mkdir -p $MODEL_DIR

# Check if model exists
MODEL_FILE="$MODEL_DIR/UD-IQ1_S/Kimi-K2-Instruct-UD-IQ1_S-00001-of-00005.gguf"

if [ ! -f "$MODEL_FILE" ]; then
    echo "Model not found. Downloading Kimi K2 model (280GB)..."
    echo "This may take 30-60 minutes depending on network speed..."
    
    python3 -c "
import os
import sys
from huggingface_hub import snapshot_download

print('Starting model download...')
try:
    os.environ['HF_HUB_ENABLE_HF_TRANSFER'] = '0'
    snapshot_download(
        repo_id='unsloth/Kimi-K2-Instruct-GGUF',
        local_dir='$MODEL_DIR',
        allow_patterns=['*UD-IQ1_S*']
    )
    print('Model download completed successfully!')
except Exception as e:
    print(f'Error downloading model: {e}')
    sys.exit(1)
"
    
    if [ $? -ne 0 ]; then
        echo "Failed to download model. Exiting."
        exit 1
    fi
else
    echo "Model already exists. Skipping download."
fi

# Verify model file exists
if [ ! -f "$MODEL_FILE" ]; then
    echo "Error: Model file not found after download: $MODEL_FILE"
    exit 1
fi

echo "Starting Kimi K2 server..."

# Start the model server
echo "Starting llama.cpp server on port 8080..."
exec ./llama.cpp/llama-cli \
    --model "$MODEL_FILE" \
    --cache-type-k q4_0 \
    --threads -1 \
    --n-gpu-layers 99 \
    --temp 0.6 \
    --min_p 0.01 \
    --ctx-size 16384 \
    --seed 3407 \
    -ot ".ffn_.*_exps.=CPU" \
    --host 0.0.0.0 \
    --port 8080
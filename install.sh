#!/usr/bin/env bash
set -e

echo "🚀 Installing Ollama and Jarvis AI Assistant..."

# -------------------------
# 1. Install Ollama
# -------------------------
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if ! command -v curl &> /dev/null; then
        echo "Installing curl..."
        sudo apt update && sudo apt install -y curl
    fi
    if ! command -v ollama &> /dev/null; then
        echo "📦 Installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found, installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install ollama
else
    echo "❌ Unsupported OS: $OSTYPE"
    exit 1
fi

echo "✅ Ollama installed!"

# Start Ollama if not running
if ! pgrep -x "ollama" > /dev/null; then
    echo "▶️ Starting Ollama service..."
    nohup ollama serve > /dev/null 2>&1 &
    sleep 3
fi

# Pull the model
MODEL="qwen2.5:0.5b"
echo "🧠 Downloading model: $MODEL"
ollama pull "$MODEL" || {
    echo "❌ Failed to pull $MODEL — check your Ollama installation or model name"
    exit 1
}
echo "✅ Model ready!"

echo "🦫 Installing OCaml environment..."

if ! command -v opam &> /dev/null; then
    sudo apt update
    sudo apt install -y opam build-essential pkg-config m4 libev-dev libgmp-dev git
fi

echo "🔧 Initializing OPAM..."
opam init -y --disable-sandboxing
eval $(opam env)

# Use latest OCaml 5.x switch
OCAML_SWITCH="5.3.0"

if ! opam switch list | grep -q "$OCAML_SWITCH"; then
    echo "📦 Creating OCaml $OCAML_SWITCH switch..."
    opam switch create "$OCAML_SWITCH" ocaml-base-compiler."$OCAML_SWITCH"
fi
eval $(opam env)

echo "📚 Installing OCaml packages..."
opam install -y dune cohttp-lwt-unix yojson bos lwt fpath




echo "🏗️ Building Jarvis..."
dune build 

echo "🚀 Installing binary..."
sudo cp ./_build/default/bin/main.exe /usr/local/bin/jarvis
sudo chmod +x /usr/local/bin/jarvis

# Create .jarvis.env configuration file
echo "🔧 Creating configuration file..."
if [ ! -f ~/.jarvis.env ]; then
    cat > ~/.jarvis.env << 'EOF'
# Jarvis AI Assistant Configuration

# Ollama API Configuration
OLLAMA_BASE_URL=http://localhost:11434
JARVIS_MODEL=gemma3:270m

# Request Configuration
JARVIS_TIMEOUT=10.0
JARVIS_NUM_CTX=512
JARVIS_NUM_PREDICT=128
JARVIS_NUM_THREADS=12

# Debug Mode (set to true or 1 to enable)
JARVIS_DEBUG=false
EOF
    echo "✅ Created ~/.jarvis.env"
else
    echo "ℹ️  ~/.jarvis.env already exists, skipping"
fi

echo "🧹 Cleaning up..."
dune clean

# -------------------------
# 4. Finish
# -------------------------
echo "✅ Installation complete!"
echo "To verify Ollama works:"
echo "  ollama run $MODEL"

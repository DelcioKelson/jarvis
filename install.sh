#!/usr/bin/env bash
set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
error()   { echo -e "${RED}✗${NC} $1"; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}── $1 ──${NC}\n"; }

# ─── Configuration ───────────────────────────────────────────────
MODEL="${JARVIS_MODEL:-functiongemma:latest}"
OCAML_SWITCH="5.3.0"
INSTALL_DIR="/usr/local/bin"

header "Installing Jarvis AI Assistant"

# ─── 1. Install Ollama ───────────────────────────────────────────
header "Step 1: Ollama"

if command -v ollama &>/dev/null; then
    success "Ollama already installed"
else
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! command -v curl &>/dev/null; then
            info "Installing curl..."
            sudo apt update && sudo apt install -y curl
        fi
        info "Installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &>/dev/null; then
            info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install ollama
    else
        error "Unsupported OS: $OSTYPE"
    fi
    success "Ollama installed"
fi

# Start Ollama if not running
if ! pgrep -x "ollama" >/dev/null 2>&1; then
    info "Starting Ollama service..."
    nohup ollama serve >/dev/null 2>&1 &
    sleep 3
fi

# Pull the model
info "Pulling model: $MODEL"
ollama pull "$MODEL" || error "Failed to pull $MODEL"
success "Model ready: $MODEL"

# ─── 2. Install OCaml ────────────────────────────────────────────
header "Step 2: OCaml Environment"

if ! command -v opam &>/dev/null; then
    info "Installing system dependencies..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt update
        sudo apt install -y opam build-essential pkg-config m4 libev-dev libgmp-dev git
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install opam pkg-config libev gmp
    fi
fi

if ! opam var root &>/dev/null 2>&1; then
    info "Initializing OPAM..."
    opam init -y --disable-sandboxing
fi
eval "$(opam env)"

if ! opam switch list 2>/dev/null | grep -q "$OCAML_SWITCH"; then
    info "Creating OCaml $OCAML_SWITCH switch..."
    opam switch create "$OCAML_SWITCH" ocaml-base-compiler."$OCAML_SWITCH"
fi
eval "$(opam env --switch=$OCAML_SWITCH)"
success "OCaml $OCAML_SWITCH ready"

info "Installing OCaml packages..."
opam install -y dune cohttp-lwt-unix yojson bos lwt fpath
success "Packages installed"

# ─── 3. Build Jarvis ─────────────────────────────────────────────
header "Step 3: Build & Install"

info "Building Jarvis..."
dune build || error "Build failed"
success "Build complete"

info "Installing binary to $INSTALL_DIR..."
sudo cp ./_build/default/bin/main.exe "$INSTALL_DIR/jarvis"
sudo chmod +x "$INSTALL_DIR/jarvis"
success "Installed: $INSTALL_DIR/jarvis"

# ─── 4. Create config ────────────────────────────────────────────
header "Step 4: Configuration"

CONFIG_FILE="$HOME/.jarvis.env"
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << EOF
# Jarvis AI Assistant Configuration

# Ollama API
OLLAMA_BASE_URL=http://localhost:11434
JARVIS_MODEL=$MODEL

# Performance
JARVIS_TIMEOUT=30.0
JARVIS_NUM_CTX=512
JARVIS_NUM_PREDICT=256
JARVIS_NUM_THREADS=4

# Debug
JARVIS_DEBUG=false
EOF
    success "Created $CONFIG_FILE"
else
    warn "$CONFIG_FILE already exists, skipping"
fi

# ─── 5. Clean up ─────────────────────────────────────────────────
dune clean

# ─── Done ─────────────────────────────────────────────────────────
header "Installation Complete!"
echo -e "  ${BOLD}Try it:${NC}"
echo -e "    jarvis -q \"What is the capital of France?\""
echo -e "    jarvis -c \"list files in current directory\""
echo -e "    jarvis -i    ${CYAN}# interactive mode${NC}"
echo -e "    jarvis --help"
echo ""
echo -e "  ${BOLD}Config:${NC} $CONFIG_FILE"
echo -e "  ${BOLD}Model:${NC}  $MODEL"
echo ""

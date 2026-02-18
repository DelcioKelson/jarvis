#!/usr/bin/env bash
set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}ℹ${NC}  $1"; }
success() { echo -e "${GREEN}✓${NC}  $1"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
error()   { echo -e "${RED}✗${NC}  $1"; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}─── $1 ───${NC}\n"; }
ask()     { echo -en "${CYAN}?${NC}  $1 "; }

# ─── Configuration ───────────────────────────────────────────────
MODEL="${JARVIS_MODEL:-functiongemma:latest}"
OCAML_SWITCH="5.3.0"
PREFIX="${PREFIX:-/usr/local}"
BINDIR="${BINDIR:-$PREFIX/bin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/jarvis"
CONFIG_FILE="$CONFIG_DIR/config.env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Parse arguments ─────────────────────────────────────────────
SKIP_OLLAMA=false
SKIP_OCAML=false
SKIP_MODEL=false

for arg in "$@"; do
    case "$arg" in
        --skip-ollama) SKIP_OLLAMA=true ;;
        --skip-ocaml)  SKIP_OCAML=true ;;
        --skip-model)  SKIP_MODEL=true ;;
        --help)
            echo -e "${BOLD}Jarvis Installer${NC}"
            echo ""
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-ollama   Skip Ollama installation"
            echo "  --skip-ocaml    Skip OCaml/opam setup (use existing)"
            echo "  --skip-model    Skip pulling the Ollama model"
            echo "  --help          Show this help"
            echo ""
            echo "Environment:"
            echo "  JARVIS_MODEL    Model to pull (default: functiongemma:latest)"
            echo "  PREFIX          Install prefix (default: /usr/local)"
            echo "  BINDIR          Binary directory (default: \$PREFIX/bin)"
            echo ""
            exit 0
            ;;
        *)
            warn "Unknown option: $arg"
            ;;
    esac
done

header "Installing Jarvis AI Assistant"
echo -e "  Binary:  ${BOLD}$BINDIR/jarvis${NC}"
echo -e "  Config:  ${BOLD}$CONFIG_DIR/${NC}"
echo -e "  Model:   ${BOLD}$MODEL${NC}"
echo ""

# ─── 1. Install Ollama ───────────────────────────────────────────
if [ "$SKIP_OLLAMA" = false ]; then
    header "Step 1/4 · Ollama"

    if command -v ollama &>/dev/null; then
        success "Ollama already installed ($(ollama --version 2>/dev/null || echo 'unknown'))"
    else
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            command -v curl &>/dev/null || {
                info "Installing curl..."
                sudo apt update -qq && sudo apt install -y -qq curl
            }
            info "Installing Ollama..."
            curl -fsSL https://ollama.com/install.sh | sh
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            command -v brew &>/dev/null || {
                info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            }
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
    if [ "$SKIP_MODEL" = false ]; then
        info "Pulling model: $MODEL (this may take a while)..."
        ollama pull "$MODEL" || error "Failed to pull $MODEL"
        success "Model ready: $MODEL"
    fi
else
    info "Skipping Ollama installation (--skip-ollama)"
fi

# ─── 2. Install OCaml ────────────────────────────────────────────
if [ "$SKIP_OCAML" = false ]; then
    header "Step 2/4 · OCaml Environment"

    if ! command -v opam &>/dev/null; then
        info "Installing system dependencies..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt update -qq
            sudo apt install -y -qq opam build-essential pkg-config m4 libev-dev libgmp-dev git
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
    opam install -y dune cohttp-lwt-unix yojson bos lwt fpath 2>/dev/null
    success "Packages installed"
else
    info "Skipping OCaml setup (--skip-ocaml)"
    eval "$(opam env)" 2>/dev/null || true
fi

# ─── 3. Build & Install ──────────────────────────────────────────
header "Step 3/4 · Build & Install"

info "Building Jarvis..."
dune build || error "Build failed"
success "Build complete"

info "Installing binary to $BINDIR..."
sudo install -Dm755 _build/default/bin/main.exe "$BINDIR/jarvis"
success "Installed: $BINDIR/jarvis"

# ─── 4. Configuration ────────────────────────────────────────────
header "Step 4/4 · Configuration"

mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
    cp "$SCRIPT_DIR/.env.example" "$CONFIG_FILE"
    # Patch the model into the config
    sed -i "s|JARVIS_MODEL=.*|JARVIS_MODEL=$MODEL|" "$CONFIG_FILE"
    success "Created config: $CONFIG_FILE"
else
    warn "Config already exists: $CONFIG_FILE (not overwritten)"
fi

# Shell completions
if [ -d "$SCRIPT_DIR/scripts" ]; then
    FISH_COMP_DIR="${HOME}/.config/fish/completions"
    if [ -d "$(dirname "$FISH_COMP_DIR")" ] && [ -f "$SCRIPT_DIR/scripts/jarvis.fish" ]; then
        mkdir -p "$FISH_COMP_DIR"
        cp "$SCRIPT_DIR/scripts/jarvis.fish" "$FISH_COMP_DIR/jarvis.fish"
        success "Fish completions installed"
    fi

    if [ -d "/etc/bash_completion.d" ] && [ -f "$SCRIPT_DIR/scripts/jarvis.bash" ]; then
        sudo cp "$SCRIPT_DIR/scripts/jarvis.bash" /etc/bash_completion.d/jarvis
        success "Bash completions installed"
    fi
fi

# Clean build artifacts
dune clean

# ─── Done ─────────────────────────────────────────────────────────
header "Installation Complete!"
echo -e "  ${BOLD}Usage:${NC}"
echo -e "    jarvis -q \"What is the capital of France?\""
echo -e "    jarvis -c \"list files here\""
echo -e "    jarvis -i    ${CYAN}# interactive mode${NC}"
echo -e "    jarvis --help"
echo ""
echo -e "  ${BOLD}Config:${NC}    $CONFIG_FILE"
echo -e "  ${BOLD}Model:${NC}     $MODEL"
echo -e "  ${BOLD}Uninstall:${NC} make uninstall  ${CYAN}# or run ./uninstall.sh${NC}"
echo ""

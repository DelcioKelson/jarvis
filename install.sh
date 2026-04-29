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

# ─── Configuration ───────────────────────────────────────────────
OCAML_SWITCH="5.3.0"
PREFIX="${PREFIX:-/usr/local}"
BINDIR="${BINDIR:-$PREFIX/bin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/jarvis"
CONFIG_FILE="$CONFIG_DIR/config.env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Parse arguments ─────────────────────────────────────────────
SKIP_OCAML=false
API_KEY="${JARVIS_API_KEY:-}"

for arg in "$@"; do
    case "$arg" in
        --skip-ocaml)  SKIP_OCAML=true ;;
        --api-key=*)   API_KEY="${arg#*=}" ;;
        --help)
            echo -e "${BOLD}Jarvis Installer${NC}"
            echo ""
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-ocaml        Skip OCaml/opam setup (use existing)"
            echo "  --api-key=<key>     Set the API key non-interactively"
            echo "  --help              Show this help"
            echo ""
            echo "Environment:"
            echo "  JARVIS_API_KEY      API key (skips the interactive prompt)"
            echo "  PREFIX              Install prefix (default: /usr/local)"
            echo "  BINDIR              Binary directory (default: \$PREFIX/bin)"
            echo ""
            echo "Jarvis works with any OpenAI-compatible API. Default provider: Groq Cloud."
            echo "Get a free API key at https://console.groq.com/keys"
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
echo -e "  Config:  ${BOLD}$CONFIG_FILE${NC}"
echo ""

# ─── 1. OCaml Environment ────────────────────────────────────────
if [ "$SKIP_OCAML" = false ]; then
    header "Step 1/3 · OCaml Environment"

    if ! command -v opam &>/dev/null; then
        info "Installing system dependencies..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update -qq
            sudo apt-get install -y -qq opam build-essential pkg-config m4 libev-dev libgmp-dev git curl
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            command -v brew &>/dev/null || {
                info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            }
            brew install opam pkg-config libev gmp
        else
            error "Unsupported OS: $OSTYPE. Install opam manually: https://opam.ocaml.org/doc/Install.html"
        fi
        success "System dependencies installed"
    fi

    if ! opam var root &>/dev/null 2>&1; then
        info "Initializing opam (this may take a moment)..."
        opam init -y --disable-sandboxing --shell-setup
    fi
    eval "$(opam env)"

    if ! opam switch list 2>/dev/null | grep -q "$OCAML_SWITCH"; then
        info "Creating OCaml $OCAML_SWITCH switch (this may take several minutes)..."
        opam switch create "$OCAML_SWITCH" ocaml-base-compiler."$OCAML_SWITCH" -y
    fi
    eval "$(opam env --switch=$OCAML_SWITCH)"
    success "OCaml $OCAML_SWITCH ready"

    info "Installing OCaml packages..."
    opam install -y dune cohttp-lwt-unix yojson bos lwt
    success "Packages installed"

    # ── Verity typed prompt library ──────────────────────────────
    info "Installing Verity typed prompt library..."
    if opam list verity 2>/dev/null | grep -q 'verity'; then
        opam upgrade -y verity
    else
        opam pin add -y verity 'git+https://github.com/DelcioKelson/verity.git#main' --no-action
        opam install -y verity
    fi
    success "Verity installed"
else
    info "Skipping OCaml/Verity setup (--skip-ocaml)"
    eval "$(opam env)" 2>/dev/null || true
fi

# ─── 2. Build & Install ──────────────────────────────────────────
header "Step 2/3 · Build & Install (jarvis)"

cd "$SCRIPT_DIR"

info "Building Jarvis..."
dune build 2>&1 || error "Build failed. Run 'dune build' manually to see detailed errors."
success "Build complete"

info "Installing binary to $BINDIR..."
sudo install -Dm755 _build/default/bin/main.exe "$BINDIR/jarvis"
success "Installed: $BINDIR/jarvis"

dune clean

# ─── 3. Configuration ────────────────────────────────────────────
header "Step 3/3 · Configuration"

mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
    cp "$SCRIPT_DIR/.env.example" "$CONFIG_FILE"
    success "Created config: $CONFIG_FILE"
else
    warn "Config already exists: $CONFIG_FILE (not overwritten)"
fi

# Prompt for API key if not already provided or set in config
if [ -z "$API_KEY" ] && ! grep -q "^JARVIS_API_KEY=[^#y]" "$CONFIG_FILE" 2>/dev/null; then
    echo ""
    echo -e "  Jarvis needs an API key to talk to the LLM."
    echo -e "  Get a free Groq key at ${BOLD}https://console.groq.com/keys${NC}"
    echo ""
    echo -en "${CYAN}?${NC}  Paste your API key (or press Enter to skip): "
    read -r API_KEY || true
fi

if [ -n "$API_KEY" ]; then
    sed -i.bak "s|^JARVIS_API_KEY=.*|JARVIS_API_KEY=$API_KEY|" "$CONFIG_FILE" && rm -f "$CONFIG_FILE.bak"
    success "API key saved to $CONFIG_FILE"
else
    warn "No API key set. Edit $CONFIG_FILE and add JARVIS_API_KEY=<your-key> before using jarvis."
fi

# Shell completions
FISH_COMP_DIR="${HOME}/.config/fish/completions"
if [ -d "${HOME}/.config/fish" ] && [ -f "$SCRIPT_DIR/scripts/jarvis.fish" ]; then
    mkdir -p "$FISH_COMP_DIR"
    cp "$SCRIPT_DIR/scripts/jarvis.fish" "$FISH_COMP_DIR/jarvis.fish"
    success "Fish completions installed"
fi

if [ -d "/etc/bash_completion.d" ] && [ -f "$SCRIPT_DIR/scripts/jarvis.bash" ]; then
    sudo cp "$SCRIPT_DIR/scripts/jarvis.bash" /etc/bash_completion.d/jarvis
    success "Bash completions installed"
fi

# ─── Done ─────────────────────────────────────────────────────────
header "Installation Complete!"
echo -e "  ${BOLD}Quick start:${NC}"
echo -e "    jarvis -q \"What is the capital of France?\""
echo -e "    jarvis -c \"list files here\""
echo -e "    jarvis -i      ${CYAN}# interactive REPL${NC}"
echo -e "    jarvis --help"
echo ""
echo -e "  ${BOLD}Config file:${NC}  $CONFIG_FILE"
echo -e "  ${BOLD}Uninstall:${NC}    ./uninstall.sh  ${CYAN}# or: make uninstall${NC}"
echo ""

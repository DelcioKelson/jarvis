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
header()  { echo -e "\n${BOLD}${CYAN}─── $1 ───${NC}\n"; }

# ─── Configuration ───────────────────────────────────────────────
PREFIX="${PREFIX:-/usr/local}"
BINDIR="${BINDIR:-$PREFIX/bin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/jarvis"
LEGACY_CONFIG="$HOME/.jarvis.env"
BIN_NAME="jarvis"

# ─── Parse arguments ─────────────────────────────────────────────
PURGE=false
YES=false

for arg in "$@"; do
    case "$arg" in
        --purge) PURGE=true ;;
        -y|--yes) YES=true ;;
        --help)
            echo -e "${BOLD}Jarvis Uninstaller${NC}"
            echo ""
            echo "Usage: ./uninstall.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --purge   Also remove config files without asking"
            echo "  -y, --yes Skip confirmation prompt"
            echo "  --help    Show this help"
            echo ""
            exit 0
            ;;
        *)
            warn "Unknown option: $arg"
            ;;
    esac
done

header "Uninstalling Jarvis"

# ─── Confirm ─────────────────────────────────────────────────────
if [ "$YES" = false ]; then
    echo -e "This will remove:"
    [ -f "$BINDIR/$BIN_NAME" ] && echo -e "  ${RED}•${NC} $BINDIR/$BIN_NAME"
    [ "$PURGE" = true ] && [ -d "$CONFIG_DIR" ] && echo -e "  ${RED}•${NC} $CONFIG_DIR/"
    [ "$PURGE" = true ] && [ -f "$LEGACY_CONFIG" ] && echo -e "  ${RED}•${NC} $LEGACY_CONFIG"
    echo ""
    echo -en "${CYAN}?${NC}  Continue? [y/N] "
    read -r answer
    if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
        info "Aborted."
        exit 0
    fi
fi

# ─── Remove binary ──────────────────────────────────────────────
if [ -f "$BINDIR/$BIN_NAME" ]; then
    sudo rm -f "$BINDIR/$BIN_NAME"
    success "Removed binary: $BINDIR/$BIN_NAME"
else
    info "Binary not found at $BINDIR/$BIN_NAME (already removed)"
fi

# ─── Remove config ──────────────────────────────────────────────
if [ "$PURGE" = true ]; then
    # Remove config dir
    if [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
        success "Removed config: $CONFIG_DIR"
    fi
    # Remove legacy config
    if [ -f "$LEGACY_CONFIG" ]; then
        rm -f "$LEGACY_CONFIG"
        success "Removed legacy config: $LEGACY_CONFIG"
    fi
else
    # Ask interactively
    if [ -d "$CONFIG_DIR" ]; then
        echo -en "${CYAN}?${NC}  Remove config directory $CONFIG_DIR? [y/N] "
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            rm -rf "$CONFIG_DIR"
            success "Removed config: $CONFIG_DIR"
        else
            info "Config preserved: $CONFIG_DIR"
        fi
    fi
    if [ -f "$LEGACY_CONFIG" ]; then
        echo -en "${CYAN}?${NC}  Remove legacy config $LEGACY_CONFIG? [y/N] "
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            rm -f "$LEGACY_CONFIG"
            success "Removed legacy config"
        else
            info "Legacy config preserved"
        fi
    fi
fi

# ─── Remove shell completions ───────────────────────────────────
FISH_COMP="$HOME/.config/fish/completions/jarvis.fish"
BASH_COMP="/etc/bash_completion.d/jarvis"

if [ -f "$FISH_COMP" ]; then
    rm -f "$FISH_COMP"
    success "Removed fish completions"
fi

if [ -f "$BASH_COMP" ]; then
    sudo rm -f "$BASH_COMP"
    success "Removed bash completions"
fi

# ─── Done ────────────────────────────────────────────────────────
header "Uninstall Complete"
echo -e "  Jarvis has been removed from your system."
echo -e "  To reinstall, run: ${CYAN}./install.sh${NC}"
echo ""

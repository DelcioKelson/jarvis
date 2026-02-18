# ── Jarvis Makefile ──────────────────────────────────────────────
# Usage:
#   make              Build the project
#   make install      Install binary + config
#   make uninstall    Remove binary + config
#   make reinstall    Clean rebuild + install
#   make clean        Remove build artifacts
#   make dev          Build in watch mode
#   make doc          Generate documentation

PREFIX        ?= /usr/local
BINDIR        ?= $(PREFIX)/bin
CONFIG_DIR    ?= $(HOME)/.config/jarvis
CONFIG_FILE   ?= $(CONFIG_DIR)/config.env
BIN_NAME      ?= jarvis
BUILD_EXE     := _build/default/bin/main.exe

BOLD := \033[1m
CYAN := \033[0;36m
GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m

.PHONY: all build install uninstall reinstall clean dev doc help

all: build

# ── Build ───────────────────────────────────────────────────────
build:
	@printf "$(CYAN)Building $(BIN_NAME)...$(NC)\n"
	@dune build
	@printf "$(GREEN)✓ Build complete$(NC) → $(BUILD_EXE)\n"

# ── Install ─────────────────────────────────────────────────────
install: build
	@printf "$(CYAN)Installing $(BIN_NAME)...$(NC)\n"
	@# Binary
	@sudo install -Dm755 $(BUILD_EXE) $(BINDIR)/$(BIN_NAME)
	@printf "$(GREEN)✓$(NC) Binary  → $(BINDIR)/$(BIN_NAME)\n"
	@# Config directory
	@mkdir -p $(CONFIG_DIR)
	@# Config file (don't overwrite existing)
	@if [ ! -f "$(CONFIG_FILE)" ]; then \
		cp .env.example $(CONFIG_FILE); \
		printf "$(GREEN)✓$(NC) Config  → $(CONFIG_FILE)\n"; \
	else \
		printf "$(CYAN)ℹ$(NC) Config already exists, skipping: $(CONFIG_FILE)\n"; \
	fi
	@# Shell completions (fish)
	@if [ -d "$(HOME)/.config/fish/completions" ]; then \
		cp scripts/jarvis.fish $(HOME)/.config/fish/completions/jarvis.fish 2>/dev/null && \
		printf "$(GREEN)✓$(NC) Fish completions installed\n" || true; \
	fi
	@# Shell completions (bash)
	@if [ -d "/etc/bash_completion.d" ]; then \
		sudo cp scripts/jarvis.bash /etc/bash_completion.d/jarvis 2>/dev/null && \
		printf "$(GREEN)✓$(NC) Bash completions installed\n" || true; \
	fi
	@printf "\n$(GREEN)$(BOLD)✓ $(BIN_NAME) installed successfully!$(NC)\n"
	@printf "  Run '$(BIN_NAME) --help' to get started.\n\n"

# ── Uninstall ───────────────────────────────────────────────────
uninstall:
	@printf "$(RED)Uninstalling $(BIN_NAME)...$(NC)\n"
	@# Binary
	@if [ -f "$(BINDIR)/$(BIN_NAME)" ]; then \
		sudo rm -f $(BINDIR)/$(BIN_NAME); \
		printf "$(GREEN)✓$(NC) Removed binary: $(BINDIR)/$(BIN_NAME)\n"; \
	else \
		printf "$(CYAN)ℹ$(NC) Binary not found at $(BINDIR)/$(BIN_NAME)\n"; \
	fi
	@# Ask about config
	@if [ -d "$(CONFIG_DIR)" ]; then \
		printf "$(CYAN)?$(NC) Remove config directory $(CONFIG_DIR)? [y/N] "; \
		read -r answer; \
		if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ]; then \
			rm -rf $(CONFIG_DIR); \
			printf "$(GREEN)✓$(NC) Removed config: $(CONFIG_DIR)\n"; \
		else \
			printf "$(CYAN)ℹ$(NC) Config preserved: $(CONFIG_DIR)\n"; \
		fi; \
	fi
	@# Legacy config cleanup
	@if [ -f "$(HOME)/.jarvis.env" ]; then \
		printf "$(CYAN)?$(NC) Remove legacy config $(HOME)/.jarvis.env? [y/N] "; \
		read -r answer; \
		if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ]; then \
			rm -f $(HOME)/.jarvis.env; \
			printf "$(GREEN)✓$(NC) Removed legacy config\n"; \
		fi; \
	fi
	@# Shell completions
	@rm -f $(HOME)/.config/fish/completions/jarvis.fish 2>/dev/null || true
	@sudo rm -f /etc/bash_completion.d/jarvis 2>/dev/null || true
	@printf "\n$(GREEN)$(BOLD)✓ $(BIN_NAME) uninstalled.$(NC)\n\n"

# ── Reinstall ───────────────────────────────────────────────────
reinstall: clean install

# ── Clean ───────────────────────────────────────────────────────
clean:
	@printf "$(CYAN)Cleaning...$(NC)\n"
	@dune clean
	@printf "$(GREEN)✓ Clean$(NC)\n"

# ── Dev ─────────────────────────────────────────────────────────
dev:
	@dune build --watch

# ── Doc ─────────────────────────────────────────────────────────
doc:
	@dune build @doc
	@printf "$(GREEN)✓ Docs$(NC) → _build/default/_doc/_html/index.html\n"

# ── Help ────────────────────────────────────────────────────────
help:
	@printf "$(BOLD)Jarvis Makefile$(NC)\n\n"
	@printf "  $(CYAN)make$(NC)              Build the project\n"
	@printf "  $(CYAN)make install$(NC)      Install binary + config (~/.config/jarvis/)\n"
	@printf "  $(CYAN)make uninstall$(NC)    Remove binary + config\n"
	@printf "  $(CYAN)make reinstall$(NC)    Clean rebuild + install\n"
	@printf "  $(CYAN)make clean$(NC)        Remove build artifacts\n"
	@printf "  $(CYAN)make dev$(NC)          Build in watch mode\n"
	@printf "  $(CYAN)make doc$(NC)          Generate documentation\n"
	@printf "  $(CYAN)make help$(NC)         Show this help\n"
	@printf "\n$(BOLD)Variables$(NC)\n\n"
	@printf "  $(CYAN)PREFIX$(NC)            Install prefix      (default: /usr/local)\n"
	@printf "  $(CYAN)BINDIR$(NC)            Binary directory     (default: \$$PREFIX/bin)\n"
	@printf "  $(CYAN)CONFIG_DIR$(NC)        Config directory     (default: ~/.config/jarvis)\n"
	@printf "\n$(BOLD)Examples$(NC)\n\n"
	@printf "  make install PREFIX=/opt/jarvis\n"
	@printf "  make uninstall\n\n"

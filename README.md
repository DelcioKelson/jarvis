# Jarvis — AI-powered CLI Assistant

A fast, type-safe CLI assistant powered by [Ollama](https://ollama.com) that converts natural language into safe system commands or answers questions directly.

Built in OCaml with a clean modular architecture, Result-based error handling, and zero unsafe shell execution.

## Features

- **Natural language command execution** — describe what you want, Jarvis runs the right command
- **Question answering** — ask anything and get a direct response
- **Interactive REPL mode** — persistent session with command history
- **Type-safe commands** — only whitelisted, safe commands are executed
- **Structured JSON output** — Ollama returns JSON that maps to typed OCaml variants
- **Colored terminal output** — clean, readable output with ANSI colors
- **Configurable** — model, timeouts, threads via env vars or config files
- **Health checks** — verifies Ollama connectivity before starting

## Quick Start

### Prerequisites

- **OCaml** >= 4.14
- **Dune** >= 3.10
- **Ollama** running locally (default: `http://localhost:11434`)

### Installation

```bash
git clone https://github.com/DelcioKelson/jarvis.git
cd jarvis
chmod +x install.sh
./install.sh
```

### Usage

```bash
# Ask a question
jarvis -q "What is the capital of France?"

# Execute a command from natural language
jarvis -c "list files in current directory"
jarvis -c "create a directory called test"
jarvis -c "show first 20 lines of README.md"
jarvis -c "find all .ml files"
jarvis -c "show disk usage"

# Use a specific model
jarvis -m llama3 -q "Explain monads"

# Start interactive mode
jarvis -i

# Enable debug output
jarvis -d -c "show current directory"

# Show help
jarvis --help

# Show version
jarvis --version
```

### Interactive Mode

Start a persistent session where you can ask questions or run commands:

```bash
jarvis -i
```

Inside the REPL:

- Type a question directly to get an answer
- Prefix with `/c` to execute a command (e.g., `/c list files`)
- Type `/help` for available commands
- Type `/model` to see current model
- Type `/debug` to toggle debug mode
- Type `/clear` to clear the screen
- Type `exit` or `quit` to leave

## Supported Commands

| Command | Description | Example |
| ------- | ----------- | ------- |
| `ls [path]` | List directory contents | "list files in /tmp" |
| `mkdir <path>` | Create directories | "create a folder called docs" |
| `echo <text>` | Print text | "echo hello world" |
| `pwd` | Print working directory | "show current directory" |
| `cat <path>` | Display file contents | "show contents of config.ml" |
| `head <path>` | First N lines of a file | "show first 20 lines of log.txt" |
| `tail <path>` | Last N lines of a file | "show last 5 lines of error.log" |
| `find <path>` | Search for files | "find all .txt files" |
| `grep <pattern> <path>` | Search text in files | "search for 'error' in app.log" |
| `wc <path>` | Count lines/words/bytes | "count lines in README.md" |
| `du [path]` | Disk usage | "show disk usage" |
| `df` | Disk space | "show free disk space" |
| `whoami` | Current user | "who am I" |
| `hostname` | System hostname | "show hostname" |
| `date` | Current date/time | "what time is it" |
| `env [var]` | Environment variables | "show PATH variable" |

## Configuration

Configuration is loaded in priority order:

1. **System environment variables** (highest priority)
2. **`.env` file** in current directory
3. **`~/.jarvis.env`** (user-global config)
4. **Built-in defaults**

### Available Settings

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `OLLAMA_BASE_URL` | `http://localhost:11434` | Ollama API URL |
| `JARVIS_MODEL` | `qwen2.5:0.5b` | Default Ollama model |
| `JARVIS_TIMEOUT` | `30.0` | Request timeout (seconds) |
| `JARVIS_NUM_CTX` | `512` | Context window size |
| `JARVIS_NUM_PREDICT` | `256` | Max tokens to generate |
| `JARVIS_NUM_THREADS` | `4` | CPU threads for inference |
| `JARVIS_DEBUG` | `false` | Enable debug logging |

### Example `.env`

```bash
OLLAMA_BASE_URL=http://localhost:11434
JARVIS_MODEL=qwen2.5:0.5b
JARVIS_TIMEOUT=30.0
JARVIS_DEBUG=false
```

## Project Structure

```text
jarvis/
├── bin/
│   ├── dune               # Executable build config
│   └── main.ml            # CLI parsing, REPL, entry point
├── lib/
│   ├── dune               # Library build config
│   ├── jarvis.ml/mli      # Top-level module re-exports
│   ├── config.ml/mli      # Configuration loading (.env, env vars)
│   ├── error.ml/mli       # Error types with exit codes
│   ├── utils.ml/mli       # Colors, JSON helpers, formatting
│   ├── command.ml/mli     # Command types, JSON schema, parsing
│   ├── executor.ml/mli    # Safe command execution via Bos
│   └── api.ml/mli         # Ollama API client, health check
├── dune-project
├── install.sh
├── .env.example
└── README.md
```

## Architecture

```text
User Input → CLI Parser → Ollama API → JSON Parser → Command Type → Executor → Output
                              ↓
                        Health Check
```

- **Commands** are represented as OCaml variant types — only valid commands can be constructed
- **Execution** uses [Bos](https://erratique.ch/software/bos) for safe OS interaction (no `system()` calls)
- **Errors** are propagated as `Result` types — no exceptions in the happy path
- **API responses** are validated through JSON schema enforcement in Ollama

## License

MIT License — see [LICENSE](LICENSE) for details.

## Support

For issues, questions, or contributions, please open an issue on the [GitHub repository](https://github.com/DelcioKelson/jarvis).

---

Made with OCaml and Ollama

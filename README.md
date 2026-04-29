# Jarvis

AI-powered CLI assistant (v2.0.0) — convert natural language into system commands or get instant answers, powered by any OpenAI-compatible API.

Prompts are defined in the [Verity](https://github.com/DelcioKelson/verity) typed prompt language, giving Jarvis compile-time type safety, structured retries, and schema-validated LLM responses.

---

## Features

- **Command mode** — describe what you want in plain English; Jarvis converts it into a safe system command and runs it
- **Question mode** — ask factual questions and get concise answers
- **Interactive REPL** — persistent session with `/c` prefix for commands
- **Type-safe prompts** — prompt definitions live in `prompts/jarvis.vrt` (Verity DSL); the runtime validates every LLM response against a declared output schema
- **Retry with repair** — failed or malformed responses are automatically retried with a hint derived from the validation error
- **Any OpenAI-compatible API** — works with Groq, Ollama, OpenAI, and any compatible endpoint

## Supported Commands

| Category | Commands |
|----------|----------|
| Read-only | `ls`, `pwd`, `cat`, `head`, `tail`, `find`, `grep`, `wc`, `du`, `df`, `whoami`, `hostname`, `date`, `env`, `echo` |
| Write | `mkdir` |

Path traversal (`..`) is rejected before any command runs.

---

## Installation

### Quick install (recommended)

```bash
git clone https://github.com/DelcioKelson/jarvis.git
cd jarvis
./install.sh
```

The installer:
1. Installs **opam** and creates an OCaml 5.3.0 switch (if needed)
2. Installs OCaml dependencies (`dune`, `cohttp-lwt-unix`, `yojson`, `bos`, `lwt`)
3. Installs the **Verity** typed prompt library from source
4. Builds and installs the `jarvis` binary to `/usr/local/bin`
5. Creates a config file at `~/.config/jarvis/config.env`
6. Installs shell completions (Fish and Bash)

#### Installer options

```
--skip-ocaml        Skip OCaml/opam and Verity setup (use existing environment)
--api-key=<key>     Set the API key non-interactively
```

### Make targets

```
make deps         Install OCaml + Verity dependencies
make build        Build the binary
make install      Build + install binary, config, and completions
make uninstall    Remove binary and completions
make reinstall    Clean rebuild + install
make clean        Remove build artifacts
make dev          Build in watch mode (dune --watch)
make doc          Generate odoc HTML documentation
```

---

## Configuration

Config is loaded in priority order:

1. Environment variables
2. `.env` in the current directory
3. `~/.config/jarvis/config.env`
4. `~/.jarvis.env` (legacy)

| Variable | Required | Default | Description |
|---|---|---|---|
| `JARVIS_API_KEY` | Yes | — | API key for the LLM provider |
| `JARVIS_API_BASE_URL` | No | `https://api.groq.com/openai/v1` | API base URL |
| `JARVIS_MODEL` | No | `llama-3.3-70b-versatile` | Model name |
| `JARVIS_TIMEOUT` | No | `30.0` | Request timeout in seconds |
| `JARVIS_DEBUG` | No | `false` | Print raw prompts and responses |

Get a free Groq API key at <https://console.groq.com/keys>.

---

## Usage

```
jarvis [OPTIONS] <MODE> "your input"

Modes:
  -c, --command "text"    Execute a system command from natural language
  -q, --question "text"   Ask a question and get an answer
  -i, --interactive       Start interactive REPL mode

Options:
  -m, --model <name>      Override the model
  -d, --debug             Enable debug output
  -h, --help              Show help
  -v, --version           Show version
```

### Examples

```bash
# Questions
jarvis -q "What is the capital of France?"

# Commands
jarvis -c "list files in the current directory"
jarvis -c "show the first 20 lines of README.md"
jarvis -c "find all .ml files under src/"
jarvis -c "create a directory called test"
jarvis -c "how much disk space is free?"

# Override model
jarvis -m llama3 -c "show disk usage"

# Interactive REPL
jarvis -i
# Inside REPL:
#   <text>      → question
#   /c <text>   → command
#   /model      → show current model
#   /debug      → toggle debug mode
#   /clear      → clear screen
#   exit        → quit
```

---

## How It Works

```
User input
    │
    ▼
lib/api.ml  ──── Verity runtime ────▶  prompts/jarvis.vrt
    │               │                    parse_command / answer_question
    │         (compile, HTTP call,
    │          retry, validation)
    ▼
lib/command.ml  (parse JSON → Command.t)
    │
    ▼
lib/executor.ml  (safe execution via Bos)
    │
    ▼
Output
```

Prompts are embedded from `prompts/jarvis.vrt` at startup. The Verity runtime handles:
- Rendering `{{request}}` / `{{query}}` template variables
- Injecting a JSON schema into the system prompt
- Validating the response against the declared output type
- Retrying with a repair hint on schema violations

---

## Project Structure

```
jarvis/
├── bin/main.ml          CLI entry point (arg parsing, REPL)
├── lib/
│   ├── api.ml           LLM calls via Verity runtime
│   ├── command.ml       Command type + JSON parser
│   ├── executor.ml      Safe command execution
│   ├── config.ml        Env var + .env loading
│   ├── utils.ml         Colors, logging, JSON helpers
│   └── error.ml         Error types + exit codes
└── prompts/
    └── jarvis.vrt       Verity prompt definitions
```

---

## Uninstall

```bash
./uninstall.sh          # interactive (asks about config removal)
./uninstall.sh --purge  # remove everything including config
make uninstall          # via Make
```

---

## License

MIT

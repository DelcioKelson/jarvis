# Jarvis - AI-powered CLI Assistant# Jarvis — AI Command Assistant


CLI assistant powered by [Ollama](https://ollama.com) that can execute commands and answer questions through natural language.Jarvis is a small program that uses [Ollama](https://ollama.com) and a local model (e.g. `qwen2.5:0.5b`) to interpret natural language requests and execute safe system commands like `ls`, `mkdir`, and `echo`.



## ✨ Features---



-  Natural language command execution## 🚀 Installation
-  Question answering mode
-  Type-safe error handling with Result types```bash
-  Clean, modular architecturegit clone https://github.com/DelcioKelson/jarvis.git
-  Production-ready code structurecd jarvis
-  Comprehensive documentation with `.mli` interfaceschmod +x install.sh

./install.sh

## 🚀 Quick Start

### Prerequisites

- **OCaml** >= 4.14
- **Dune** >= 3.10
- **Ollama** running locally on port 11434

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

# Execute a command
jarvis -c "list files in current directory"
jarvis -c "create a directory called test"
jarvis -c "show current directory"
jarvis -c "show contents of README.md"
```

## 📁 Project Structure

The project follows a clean, modular architecture:

```
jarvis/
├── bin/                    # Executable entry point
│   ├── dune
│   └── main.ml            # CLI argument parsing and entry point
├── lib/                    # Library modules
│   ├── dune
│   ├── jarvis.ml          # Main library interface
│   ├── jarvis.mli
│   ├── config.ml          # Configuration module
│   ├── config.mli
│   ├── error.ml           # Error types and handling
│   ├── error.mli
│   ├── utils.ml           # Utility functions
│   ├── utils.mli
│   ├── command.ml         # Command types and parsing
│   ├── command.mli
│   ├── executor.ml        # Command execution logic
│   ├── executor.mli
│   ├── api.ml             # Ollama API interaction
│   └── api.mli
├── dune-project           # Dune project configuration
├── ARCHITECTURE.md        # Detailed architecture documentation
├── CHANGELOG.md           # Version history
├── LICENSE               # MIT License
└── README.md             # This file
```

## 🏗️ Architecture

The project is organized into focused, single-responsibility modules:

- **Config**: Centralized configuration management (API URLs, models, timeouts)
- **Error**: Strongly-typed error handling with custom error variants
- **Utils**: Shared utilities (debug logging, JSON extraction helpers)
- **Command**: Command type definitions and JSON schema-based parsing
- **Executor**: Safe command execution with proper error handling
- **Api**: Ollama API communication and request/response processing

### Design Principles

1. **Separation of Concerns**: Each module has a single, well-defined responsibility
2. **Type Safety**: Extensive use of Result types and pattern matching
3. **Interface Files**: All modules have `.mli` files defining clear public APIs
4. **Error Handling**: Comprehensive error types with proper propagation
5. **Documentation**: OCamldoc comments throughout the codebase

For detailed architecture documentation, see [ARCHITECTURE.md](ARCHITECTURE.md).

## 🛠️ Supported Commands

Currently supported commands:

- `ls [path]` - List directory contents
- `mkdir <path>` - Create directories
- `echo <text>` - Echo text output
- `pwd` - Print working directory
- `cat <path>` - Display file contents

## ⚙️ Configuration

Default configuration in `lib/config.ml`:

```ocaml
let ollama_base_url = "http://localhost:11434"
let default_model = "qwen2.5:0.5b"
let request_timeout = 10.0
let debug = ref false
```

To enable debug logging, modify `Config.debug` before building, or add a runtime flag (future enhancement).

## 📚 Dependencies

- **cohttp-lwt-unix** (>= 5.0) - HTTP client with Lwt async support
- **yojson** (>= 2.0) - JSON parsing and manipulation
- **bos** (>= 0.2) - OS interaction primitives
- **lwt** (>= 5.6) - Asynchronous programming library

## 🔧 Development

### Building

```bash
dune build
```

### Watch mode for development

```bash
dune build --watch
```

### Generate documentation

```bash
dune build @doc
# Documentation will be in _build/default/_doc/_html/
```

### Clean build artifacts

```bash
dune clean
```

### Format code (requires ocamlformat)

```bash
dune build @fmt --auto-promote
```

## 🧪 Testing

(Tests to be added in future versions)

```bash
dune runtest
```

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:
- Code follows the existing style
- All modules have corresponding `.mli` interface files
- Documentation is updated
- New features include tests (when testing framework is added)

## 🐛 Troubleshooting

**Timeout errors**: Increase `Config.request_timeout` if you see `TimeoutError`.

**Invalid JSON responses**: Enable debug logging by setting `Config.debug := true` to see raw API responses.

**Ollama connection issues**: Ensure Ollama is running at `http://localhost:11434`:
```bash
curl http://localhost:11434/api/tags
```

**Filesystem permission errors**: Ensure you have proper permissions for the operations you're attempting.

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

## 📋 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## 🗺️ Roadmap

Future enhancements:

- [ ] Add comprehensive test suite
- [ ] Add more shell commands (`mv`, `cp`, `rm`, etc.)
- [ ] Configuration file support (`.jarvisrc`)
- [ ] Command history and caching
- [ ] Interactive mode
- [ ] Plugin system for custom commands
- [ ] Remote Ollama server support
- [ ] Logging to file with rotation
- [ ] Shell completion scripts

## 📞 Support

For issues, questions, or contributions, please open an issue on the [GitHub repository](https://github.com/DelcioKelson/jarvis).

---

Made with ❤️ using OCaml and Ollama

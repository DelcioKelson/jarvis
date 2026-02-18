# Fish shell completions for jarvis

# Modes
complete -c jarvis -s c -l command     -d "Execute a command from natural language"
complete -c jarvis -s q -l question    -d "Ask a question"
complete -c jarvis -s i -l interactive -d "Start interactive REPL"

# Options
complete -c jarvis -s m -l model   -d "Override the Ollama model" -x
complete -c jarvis -s d -l debug   -d "Enable debug output"
complete -c jarvis -s h -l help    -d "Show help"
complete -c jarvis -s v -l version -d "Show version"

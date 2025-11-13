# New Read-Only Commands

The following read-only commands have been added to Jarvis. These commands do not modify the system state.

## Text File Commands

### head
Display the first N lines of a file (default: 10).
```bash
jarvis -c "show first 5 lines of config.ml"
jarvis -c "head of README.md"
```

### tail  
Display the last N lines of a file (default: 10).
```bash
jarvis -c "show last 20 lines of log file"
jarvis -c "tail of error.log"
```

### cat
Display complete file contents (existing command).
```bash
jarvis -c "show contents of file.txt"
```

### grep
Search for text patterns in files.
```bash
jarvis -c "search for 'error' in app.log"
jarvis -c "find TODO in source files"
```

### wc
Count lines, words, and bytes in a file.
```bash
jarvis -c "count lines in README.md"
jarvis -c "word count of document.txt"
```

## File System Commands

### ls
List directory contents (existing command).
```bash
jarvis -c "list files in current directory"
jarvis -c "show files in /tmp"
```

### find
Search for files by name or pattern.
```bash
jarvis -c "find all .txt files here"
jarvis -c "search for *.ml files in lib"
```

### pwd
Print current working directory (existing command).
```bash
jarvis -c "show current directory"
```

### du
Display disk usage for a path.
```bash
jarvis -c "show disk usage of current folder"
jarvis -c "how much space does lib folder use"
```

### df
Display file system disk space usage.
```bash
jarvis -c "show disk space"
jarvis -c "check available disk space"
```

## System Information Commands

### whoami
Display current user.
```bash
jarvis -c "who am I"
jarvis -c "show current user"
```

### hostname
Display system hostname.
```bash
jarvis -c "what is the hostname"
jarvis -c "show computer name"
```

### date
Display current date and time.
```bash
jarvis -c "what time is it"
jarvis -c "show current date"
```

### env
Display environment variables.
```bash
jarvis -c "show all environment variables"
jarvis -c "what is PATH variable"
jarvis -c "show HOME environment variable"
```

## Write Commands (Existing)

### mkdir
Create a new directory (modifies system).
```bash
jarvis -c "create directory called test"
```

### echo
Print text (read-only output).
```bash
jarvis -c "say hello world"
```

## Implementation Details

### Command Types
All commands are defined in `lib/command.ml` with proper type safety:

```ocaml
type t =
  | Ls of string option
  | Mkdir of string
  | Echo of string
  | Pwd
  | Cat of string
  | Head of { path: string; lines: int option }
  | Tail of { path: string; lines: int option }
  | Find of { path: string; name: string option }
  | Grep of { pattern: string; path: string }
  | Wc of string
  | Du of string option
  | Df
  | Whoami
  | Hostname
  | Date
  | Env of string option
```

### Safety
- All commands are read-only except `mkdir`
- Path validation using Fpath library
- Error handling for all operations
- Safe command execution via Bos library

### JSON Schema
Each command has a corresponding JSON schema in `Command.format_json` for structured output from the LLM.

### Execution
Commands are executed safely in `lib/executor.ml` using the Bos library, which provides safe OS interaction primitives.

## Usage Tips

1. **Natural language**: Describe what you want in plain English
   ```bash
   jarvis -c "find all OCaml files"
   jarvis -c "show me the first 10 lines of the readme"
   ```

2. **Specific paths**: Be explicit when needed
   ```bash
   jarvis -c "list files in /home/user/projects"
   jarvis -c "search for 'error' in /var/log/app.log"
   ```

3. **Combine concepts**: Use descriptive language
   ```bash
   jarvis -c "how many lines are in the main source file"
   jarvis -c "show disk usage for the lib directory"
   ```

## Benefits

- ✅ **Safe**: Read-only operations don't modify the system
- ✅ **Type-safe**: Strong typing prevents errors
- ✅ **Extensible**: Easy to add more commands
- ✅ **Natural**: Use plain English descriptions
- ✅ **Validated**: Proper path and argument validation

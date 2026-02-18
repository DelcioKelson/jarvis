# Bash completions for jarvis
_jarvis_completions() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts="-c --command -q --question -i --interactive -m --model -d --debug -h --help -v --version"

    case "$prev" in
        -m|--model)
            # Complete with available ollama models
            local models
            models=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')
            COMPREPLY=( $(compgen -W "$models" -- "$cur") )
            return 0
            ;;
    esac

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return 0
    fi
}
complete -F _jarvis_completions jarvis

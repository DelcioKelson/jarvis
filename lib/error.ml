(** Error types for Jarvis *)

type error =
  | ParseError of string
  | ExecutionError of string
  | NetworkError of string
  | TimeoutError
  | UnknownCommand of string
  | ValidationError of string
  | ConfigError of string
  | ConnectionError of string

let to_string = function
  | ParseError msg -> Printf.sprintf "Parse error: %s" msg
  | ExecutionError msg -> Printf.sprintf "Execution error: %s" msg
  | NetworkError msg -> Printf.sprintf "Network error: %s" msg
  | TimeoutError -> "Request timed out — is Ollama running? Try increasing JARVIS_TIMEOUT"
  | UnknownCommand cmd -> Printf.sprintf "Unknown command: %s" cmd
  | ValidationError msg -> Printf.sprintf "Validation error: %s" msg
  | ConfigError msg -> Printf.sprintf "Configuration error: %s" msg
  | ConnectionError msg -> Printf.sprintf "Connection error: %s — is Ollama running at the configured URL?" msg

let exit_code = function
  | ParseError _ -> 2
  | ExecutionError _ -> 3
  | NetworkError _ -> 4
  | TimeoutError -> 5
  | UnknownCommand _ -> 6
  | ValidationError _ -> 7
  | ConfigError _ -> 8
  | ConnectionError _ -> 9

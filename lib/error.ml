(** Error types for Jarvis *)

type error =
  | ParseError of string
  | ExecutionError of string
  | NetworkError of string
  | TimeoutError
  | UnknownCommand of string

let to_string = function
  | ParseError msg -> Printf.sprintf "Parse error: %s" msg
  | ExecutionError msg -> Printf.sprintf "Execution error: %s" msg
  | NetworkError msg -> Printf.sprintf "Network error: %s" msg
  | TimeoutError -> "Request timeout"
  | UnknownCommand cmd -> Printf.sprintf "Unknown command: %s" cmd

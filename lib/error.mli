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

val to_string : error -> string
(** Convert an error to a human-readable string *)

val exit_code : error -> int
(** Return the appropriate exit code for an error *)

(** Error types for Jarvis *)

type error =
  | ParseError of string
  | ExecutionError of string
  | NetworkError of string
  | TimeoutError
  | UnknownCommand of string

val to_string : error -> string
(** Convert an error to a human-readable string *)

(** Command types and parsing for Jarvis *)

(** Command types *)
type t =
  | Ls of string option
  | Mkdir of string
  | Echo of string
  | Pwd
  | Cat of string

val format_json : Yojson.Basic.t
(** JSON Schema for structured output *)

val of_json : Yojson.Basic.t -> (t, Error.error) result
(** Parse command from JSON *)

val to_string : t -> string
(** Convert command to human-readable string *)

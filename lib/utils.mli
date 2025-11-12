(** Utility functions for Jarvis *)

val debug_log : ('a, unit, string, unit) format4 -> 'a
(** Debug logging helper - only prints when Config.debug is true *)

val get_string_field : Yojson.Basic.t -> string -> string option
(** Safely extract string field from JSON *)

val get_required_string : Yojson.Basic.t -> string -> (string, Error.error) result
(** Extract required string field from JSON, returns error if missing *)

val extract_json_block : string -> (string, Error.error) result
(** Extract JSON block from raw string response *)

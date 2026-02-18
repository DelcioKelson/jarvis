(** Utility functions for Jarvis *)

(** {1 ANSI Color Helpers} *)

val bold : string -> string
val red : string -> string
val green : string -> string
val yellow : string -> string
val blue : string -> string
val cyan : string -> string
val dim : string -> string
val bold_green : string -> string
val bold_cyan : string -> string
val bold_red : string -> string
val bold_yellow : string -> string

(** {1 Debug Logging} *)

val debug_log : ('a, unit, string, unit) format4 -> 'a
(** Debug logging helper — only prints when Config.debug is true *)

(** {1 JSON Utilities} *)

val get_string_field : Yojson.Basic.t -> string -> string option
(** Safely extract string field from JSON *)

val get_required_string : Yojson.Basic.t -> string -> (string, Error.error) result
(** Extract required string field from JSON, returns error if missing *)

val extract_json_block : string -> (string, Error.error) result
(** Extract JSON block from raw string response *)

(** {1 Output Formatting} *)

val print_header : string -> unit
val print_success : string -> unit
val print_error : string -> unit
val print_warning : string -> unit
val print_info : string -> unit
val print_command : string -> unit
val print_divider : unit -> unit
val print_result : string -> unit
val print_jarvis_response : string -> unit

(** {1 Misc Utilities} *)

val string_is_empty : string -> bool

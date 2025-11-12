(** Utility functions for Jarvis *)

open Yojson.Basic.Util

(** Debug logging helper *)
let debug_log fmt =
  Printf.ksprintf (fun s ->
    if !Config.debug then
      Printf.eprintf "[DEBUG] %s\n%!" s
  ) fmt

(** Safely extract string field from JSON *)
let get_string_field json field_name =
  try
    debug_log "Getting field '%s' from JSON" field_name;
    match json |> member field_name with
    | `Null ->
        debug_log "Field '%s' is null" field_name;
        None
    | `String s ->
        debug_log "Field '%s' = %s" field_name s;
        Some s
    | other ->
        debug_log "Field '%s' has unexpected type: %s" field_name
          (Yojson.Basic.to_string other);
        None
  with exn ->
    debug_log "Exception getting field '%s': %s" field_name
      (Printexc.to_string exn);
    None

(** Extract required string field from JSON *)
let get_required_string json field_name =
  match get_string_field json field_name with
  | Some s -> Ok s
  | None -> Error (Error.ParseError (Printf.sprintf "Missing required field: %s" field_name))

(** Extract JSON block from raw string response *)
let extract_json_block (raw_reply : string) : (string, Error.error) result =
  try
    let rec find_matching_brace s pos depth =
      if pos >= String.length s then None
      else match s.[pos] with
        | '{' -> find_matching_brace s (pos + 1) (depth + 1)
        | '}' when depth = 1 -> Some pos
        | '}' -> find_matching_brace s (pos + 1) (depth - 1)
        | _ -> find_matching_brace s (pos + 1) depth
    in
    let start = String.index raw_reply '{' in
    match find_matching_brace raw_reply start 0 with
    | Some last ->
        Ok (String.sub raw_reply start (last - start + 1))
    | None ->
        Error (Error.ParseError "Malformed JSON: unmatched braces")
  with Not_found ->
    Error (Error.ParseError "No JSON block found in response")

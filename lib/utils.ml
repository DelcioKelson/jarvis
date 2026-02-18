(** Utility functions for Jarvis *)

open Yojson.Basic.Util

(* ── ANSI Color Helpers ─────────────────────────────────────────── *)

let is_tty = Unix.isatty Unix.stdout

let color code text =
  if is_tty then Printf.sprintf "\027[%sm%s\027[0m" code text
  else text

let bold text       = color "1" text
let red text        = color "0;31" text
let green text      = color "0;32" text
let yellow text     = color "0;33" text
let blue text       = color "0;34" text
let cyan text       = color "0;36" text
let dim text        = color "2" text
let bold_green text = color "1;32" text
let bold_cyan text  = color "1;36" text
let bold_red text   = color "1;31" text
let bold_yellow text = color "1;33" text

(* ── Debug Logging ──────────────────────────────────────────────── *)

let debug_log fmt =
  Printf.ksprintf (fun s ->
    if !(Config.debug) then
      Printf.eprintf "%s %s\n%!" (dim "[DEBUG]") s
  ) fmt

(* ── JSON Utilities ─────────────────────────────────────────────── *)

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

let get_required_string json field_name =
  match get_string_field json field_name with
  | Some s -> Ok s
  | None -> Error (Error.ParseError (Printf.sprintf "Missing required field: %s" field_name))

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

(* ── Output Formatting ──────────────────────────────────────────── *)

let print_header title =
  Printf.printf "\n%s %s\n" (bold_cyan "⟫") (bold title)

let print_success msg =
  Printf.printf "%s %s\n" (bold_green "✓") msg

let print_error msg =
  Printf.eprintf "%s %s\n" (bold_red "✗") msg

let print_warning msg =
  Printf.printf "%s %s\n" (bold_yellow "⚠") msg

let print_info msg =
  Printf.printf "%s %s\n" (blue "ℹ") msg

let print_command cmd =
  Printf.printf "%s %s\n" (dim "❯") (yellow cmd)

let print_divider () =
  let bar = String.concat "" (List.init 60 (fun _ -> "-")) in
  Printf.printf "%s\n" (dim bar)

let print_result output =
  Printf.printf "%s\n" output

let print_jarvis_response text =
  print_header "Jarvis";
  print_result text

(* ── Misc Utilities ─────────────────────────────────────────────── *)

let string_is_empty s = String.trim s = ""

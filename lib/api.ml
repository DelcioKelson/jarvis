(** API interaction module — powered by the Verity typed prompt runtime *)

open Lwt.Infix

(** Input type for API requests *)
type input_type =
  | Command
  | Question

(* ── Embedded Verity prompt definitions ─────────────────────────── *)

(** jarvis.vrt source embedded at compile time *)
let vrt_source = {|
prompt parse_command(request: string) -> json
  [effects: Latent(3.0), Fallible]
  retry(2) with: "Respond with ONLY valid JSON. The 'action' field must be one of the listed commands and 'args' must be an object."
  =
"""
You are a Linux command-line assistant. Convert the user request into a structured JSON command.
If a path is not specified, assume the current working directory.

Available commands: ls, mkdir, echo, pwd, cat, head, tail, find, grep, wc, du, df, whoami, hostname, date, env.

User request: {{request}}

Return JSON in exactly this format:
{"action": "<command>", "args": {<command-specific args>}}

Examples:
- List directory:      {"action": "ls",       "args": {"path": "."}}
- Show first 20 lines: {"action": "head",     "args": {"path": "file.txt", "lines": 20}}
- Show last 5 lines:   {"action": "tail",     "args": {"path": "file.txt", "lines": 5}}
- Find .txt files:     {"action": "find",     "args": {"path": ".", "name": "*.txt"}}
- Search for error:    {"action": "grep",     "args": {"pattern": "error", "path": "app.log"}}
- Create folder:       {"action": "mkdir",    "args": {"path": "Documents"}}
- Echo text:           {"action": "echo",     "args": {"text": "Hello World!"}}
- Show date:           {"action": "date",     "args": {}}
- Show pwd:            {"action": "pwd",      "args": {}}
- Disk usage:          {"action": "du",       "args": {}}
- Disk space:          {"action": "df",       "args": {}}
- Who am I:            {"action": "whoami",   "args": {}}
- Show hostname:       {"action": "hostname", "args": {}}
- Show PATH:           {"action": "env",      "args": {"variable": "PATH"}}
- Count lines:         {"action": "wc",       "args": {"path": "file.txt"}}
- Show file:           {"action": "cat",      "args": {"path": "file.txt"}}
"""

prompt answer_question(query: string) -> { answer: string }
  [effects: Latent(5.0), Fallible]
  retry(1) with: "Return JSON with exactly one field: {\"answer\": \"<your response here>\"}"
  =
"""
Answer the following question clearly and concisely.

Question: {{query}}
"""
|}

(* ── Verity IR initialisation ───────────────────────────────────── *)

let ir_program =
  let lexbuf = Lexing.from_string vrt_source in
  let prog =
    try Verity_lib.Parser.program Verity_lib.Lexer.token lexbuf
    with exn ->
      Printf.eprintf "Internal error: failed to parse embedded Verity prompts: %s\n"
        (Printexc.to_string exn);
      exit 1
  in
  Verity_lib.Compiler.compile_program prog

let get_ir name =
  match List.assoc_opt name ir_program.Verity_lib.Ir.prompts with
  | Some ir -> ir
  | None ->
      Printf.eprintf "Internal error: Verity prompt '%s' not found\n" name;
      exit 1

let parse_command_ir  = get_ir "parse_command"
let answer_question_ir = get_ir "answer_question"

(* ── Runtime config from Jarvis config ──────────────────────────── *)

let make_runtime_config model : Verity_lib.Runtime.runtime_config =
  { provider = {
      api_base = Config.api_base_url;
      api_key  = Config.api_key;
      model;
    };
    default_retry = 2;
    debug         = !(Config.debug);
    timeout_s     = Config.request_timeout;
  }

(* ── Verity → Jarvis error mapping ──────────────────────────────── *)

let map_runtime_error = function
  | Verity_lib.Runtime.HttpError (code, body) ->
      Error.NetworkError
        (Printf.sprintf "HTTP %d: %s" code
           (String.sub body 0 (min 200 (String.length body))))
  | Verity_lib.Runtime.NetworkError msg -> Error.NetworkError msg
  | Verity_lib.Runtime.Timeout          -> Error.TimeoutError
  | Verity_lib.Runtime.ParseError msg   -> Error.ParseError msg
  | Verity_lib.Runtime.ValidationFailed errs ->
      Error.ParseError
        (String.concat "; "
           (List.map Verity_lib.Validation.string_of_validation_error errs))
  | Verity_lib.Runtime.MaxRetriesExceeded -> Error.NetworkError "Max retries exceeded"
  | Verity_lib.Runtime.ConfigError msg    -> Error.ConfigError msg

(** Check if the API endpoint is reachable *)
let health_check () =
  if Config.api_key = "" then
    Lwt.return (Error (Error.ConnectionError "JARVIS_API_KEY is not set"))
  else
  let uri = Uri.of_string (Config.api_base_url ^ "/models") in
  let headers =
    Cohttp.Header.of_list [
      ("Authorization", "Bearer " ^ Config.api_key)
    ]
  in
  Lwt.catch
    (fun () ->
      Lwt.pick [
        (Cohttp_lwt_unix.Client.get ~headers uri >>= fun (resp, _body) ->
         let status = Cohttp.Response.status resp in
         if Cohttp.Code.(is_success (code_of_status status)) then
           Lwt.return (Ok ())
         else
           Lwt.return (Error (Error.ConnectionError
             (Printf.sprintf "API returned HTTP %d"
               (Cohttp.Code.code_of_status status)))));
        (Lwt_unix.sleep 5.0 >>= fun () ->
         Lwt.return (Error (Error.ConnectionError "Connection timed out")))
      ])
    (fun exn ->
      Lwt.return (Error (Error.ConnectionError (Printexc.to_string exn))))

(** Call an LLM prompt via the Verity runtime *)
let ask ?(model = Config.default_model) input_type user_input =
  let cfg = make_runtime_config model in
  let (ir, inputs) = match input_type with
    | Command  -> (parse_command_ir,   [("request", user_input)])
    | Question -> (answer_question_ir, [("query",   user_input)])
  in
  Utils.debug_log "Running Verity prompt '%s'" ir.Verity_lib.Ir.ir_name;
  Verity_lib.Runtime.run_prompt cfg ir inputs >>= function
  | Error e -> Lwt.return (Error (map_runtime_error e))
  | Ok json ->
      match input_type with
      | Command ->
          Lwt.return (Ok (Yojson.Safe.to_string json))
      | Question ->
          (match Yojson.Safe.Util.member "answer" json with
          | `String s -> Lwt.return (Ok s)
          | _ ->
              Lwt.return (Error (Error.ParseError
                "Missing 'answer' field in question response")))

(** Main processing pipeline *)
let process input_type model prompt =
  ask ~model input_type prompt >>= function
  | Error err -> Lwt.return (Error err)
  | Ok reply ->
      match input_type with
      | Question -> Lwt.return (Ok reply)
      | Command ->
          Utils.debug_log "Parsing command JSON: %s" reply;
          (try
            let json_safe  = Yojson.Safe.from_string reply in
            let json_basic = Yojson.Safe.to_basic json_safe in
            match Command.of_json json_basic with
            | Error err -> Lwt.return (Error err)
            | Ok cmd    -> Lwt.return (Executor.execute cmd)
          with exn ->
            Lwt.return (Error (Error.ParseError
              (Printf.sprintf "Invalid JSON from model: %s"
                 (Printexc.to_string exn)))))

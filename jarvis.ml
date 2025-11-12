open Lwt.Infix
open Yojson.Basic.Util

(* --- Configuration --- *)
module Config = struct
  let ollama_base_url = "http://localhost:11434"
  let default_model = "qwen2.5:0.5b"
  let request_timeout = 10.0 (* seconds *)
  let debug = ref false (* Set to false to disable debug output *)
end

(* --- Debug helper --- *)
let debug_log fmt =
  Printf.ksprintf (fun s ->
    if !Config.debug then
      Printf.eprintf "[DEBUG] %s\n%!" s
  ) fmt

(* --- Custom Result type for better error handling --- *)
type ('a, 'e) result = ('a, 'e) Result.t

(* --- Error types --- *)
type error =
  | ParseError of string
  | ExecutionError of string
  | NetworkError of string
  | TimeoutError
  | UnknownCommand of string

let error_to_string = function
  | ParseError msg -> Printf.sprintf "Parse error: %s" msg
  | ExecutionError msg -> Printf.sprintf "Execution error: %s" msg
  | NetworkError msg -> Printf.sprintf "Network error: %s" msg
  | TimeoutError -> "Request timeout"
  | UnknownCommand cmd -> Printf.sprintf "Unknown command: %s" cmd

(* --- Command types --- *)
type command =
  | Ls of string option
  | Mkdir of string
  | Echo of string
  | Pwd
  | Cat of string

(* --- JSON Schema for structured output --- *)
let format_json =
  `Assoc [
    ("type", `String "object");
    ("oneOf", `List [
      (* ls *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "ls")]);
          ("args", `Assoc [
            ("type", `String "object");
            ("properties", `Assoc [
              ("path", `Assoc [("type", `String "string")])
            ]);
            ("required", `List [`String "path"]);
            ("additionalProperties", `Bool false)
          ])
        ]);
        ("required", `List [`String "action"; `String "args"])
      ];
      (* mkdir *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "mkdir")]);
          ("args", `Assoc [
            ("type", `String "object");
            ("properties", `Assoc [
              ("path", `Assoc [("type", `String "string")])
            ]);
            ("required", `List [`String "path"]);
            ("additionalProperties", `Bool false)
          ])
        ]);
        ("required", `List [`String "action"; `String "args"])
      ];
      (* echo *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "echo")]);
          ("args", `Assoc [
            ("type", `String "object");
            ("properties", `Assoc [
              ("text", `Assoc [("type", `String "string")])
            ]);
            ("required", `List [`String "text"]);
            ("additionalProperties", `Bool false)
          ])
        ]);
        ("required", `List [`String "action"; `String "args"])
      ]
    ])
  ]

(* --- Call Ollama API with optimized structured output --- *)


(* --- Robust JSON extraction --- *)
let extract_json_block (raw_reply : string) : (string, error) result =
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
        Error (ParseError "Malformed JSON: unmatched braces")
  with Not_found ->
    Error (ParseError "No JSON block found in response")

(* --- Helper to safely extract string fields --- *)
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
  | None -> Error (ParseError (Printf.sprintf "Missing required field: %s" field_name))

(* --- Parse command from JSON --- *)
let command_of_json json : (command, error) result =
  try
    debug_log "Parsing command JSON: %s" (Yojson.Basic.to_string json);
    match get_required_string json "action" with
    | Error e ->
        debug_log "Failed to get action field";
        Error e
    | Ok action ->
        debug_log "Action: %s" action;
        let args = json |> member "args" in
        debug_log "Args: %s" (Yojson.Basic.to_string args);
        match action with
        | "ls" ->
            let path = get_string_field args "path" in
            debug_log "Ls command with path: %s"
              (Option.value path ~default:"<none>");
            Ok (Ls path)
        | "mkdir" ->
            (match get_required_string args "path" with
            | Ok path ->
                debug_log "Mkdir command with path: %s" path;
                Ok (Mkdir path)
            | Error e -> Error e)
        | "echo" ->
            (match get_required_string args "content" with
            | Ok content ->
                debug_log "Echo command with content: %s" content;
                Ok (Echo content)
            | Error e -> Error e)
        | "pwd" ->
            debug_log "Pwd command";
            Ok Pwd
        | "cat" ->
            (match get_required_string args "path" with
            | Ok path ->
                debug_log "Cat command with path: %s" path;
                Ok (Cat path)
            | Error e -> Error e)
        | unknown ->
            debug_log "Unknown action: %s" unknown;
            Error (UnknownCommand unknown)
  with
  | Yojson.Basic.Util.Type_error (msg, _) ->
      debug_log "JSON type error: %s" msg;
      Error (ParseError ("JSON type error: " ^ msg))
  | exn ->
      debug_log "Exception parsing command: %s" (Printexc.to_string exn);
      Error (ParseError (Printexc.to_string exn))

(* --- Execute command safely --- *)
let execute_command cmd : (string, error) result =
  try
    match cmd with
    | Ls path ->
        let p = Option.value path ~default:"." in
        let fpath = Fpath.v p in
        if not (Fpath.is_rel fpath || Fpath.is_abs fpath) then
          Error (ExecutionError "Invalid path")
        else
          let cmd = Bos.Cmd.(v "ls" % "-lh" % Fpath.to_string fpath) in
          (match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
          | Ok (s, _) -> Ok s
          | Error (`Msg e) -> Error (ExecutionError e))

    | Mkdir path ->
        let dir = Fpath.v path in
        (match Bos.OS.Dir.create ~mode:0o755 dir with
        | Ok _ -> Ok (Printf.sprintf "📁 Directory created: %s\n" path)
        | Error (`Msg e) -> Error (ExecutionError e))

    | Echo text ->
        Ok (text ^ "\n")

    | Pwd ->
        (match Bos.OS.Dir.current () with
        | Ok dir -> Ok (Fpath.to_string dir ^ "\n")
        | Error (`Msg e) -> Error (ExecutionError e))

    | Cat path ->
        let fpath = Fpath.v path in
        (match Bos.OS.File.read fpath with
        | Ok content -> Ok content
        | Error (`Msg e) -> Error (ExecutionError e))
  with
  | exn -> Error (ExecutionError (Printexc.to_string exn))

(* --- API call with timeout --- *)
let ask_ollama ?(model=Config.default_model) prompt =
  let uri = Uri.of_string (Config.ollama_base_url ^ "/api/chat") in
  let system_prompt =
    "You are a helpful CLI assistant. Convert user requests into structured commands. \
     Available commands: ls (list files), mkdir (create directory), echo (print text), \
     pwd (current directory), cat (read file). Respond ONLY with valid JSON matching the schema.\
     the current working directory is ."
  in
  let body =
    `Assoc [
      ("model", `String model);
      ("stream", `Bool false);
      ("messages", `List [
        `Assoc [("role", `String "system"); ("content", `String system_prompt)];
        `Assoc [("role", `String "user"); ("content", `String prompt)]
      ]);
      ("format", format_json);
      ("options", `Assoc [
        ("temperature", `Float 0.1);
        ("top_p", `Float 0.9)
      ])
    ]
    |> Yojson.Basic.to_string
  in

  let request =
    Cohttp_lwt_unix.Client.post
      ~body:(Cohttp_lwt.Body.of_string body)
      ~headers:(Cohttp.Header.init_with "Content-Type" "application/json")
      uri
    >>= fun (resp, body) ->
    let status = Cohttp.Response.status resp in
    if Cohttp.Code.(is_success (code_of_status status)) then
      Cohttp_lwt.Body.to_string body >|= fun b ->
      try
        debug_log "Raw API response: %s" b;
        let json = Yojson.Basic.from_string b in
        debug_log "Parsed API JSON successfully";
        match get_string_field (json |> member "message") "content" with
        | Some content ->
            debug_log "Extracted content from response";
            Ok content
        | None ->
            debug_log "Content field is missing or null";
            Error (NetworkError "Response missing 'content' field")
      with exn ->
        debug_log "Exception parsing API response: %s" (Printexc.to_string exn);
        Error (NetworkError ("Failed to parse response: " ^ Printexc.to_string exn))
    else
      Cohttp_lwt.Body.to_string body >>= fun err_body ->
      debug_log "HTTP error %d: %s" (Cohttp.Code.code_of_status status) err_body;
      Lwt.return (Error (NetworkError
        (Printf.sprintf "HTTP %d: %s"
          (Cohttp.Code.code_of_status status) err_body)))
  in

  (* Add timeout *)
  Lwt.pick [
    request;
    (Lwt_unix.sleep Config.request_timeout >>= fun () ->
     Lwt.return (Error TimeoutError))
  ]

(* --- Main processing pipeline --- *)
let process_request model prompt =
  ask_ollama ~model prompt >>= function
  | Error err -> Lwt.return (Error err)
  | Ok reply ->
      let () = debug_log "🤖 Model reply: %s\n\n" reply in
      match extract_json_block reply with
      | Error err -> Lwt.return (Error err)
      | Ok json_str ->
          let () = debug_log "📋 Extracted JSON: %s\n\n" json_str in
          try
            let cmd_json = Yojson.Basic.from_string json_str in
            match command_of_json cmd_json with
            | Error err -> Lwt.return (Error err)
            | Ok cmd ->
                let () = debug_log "⚙️  Executing command...\n" in
                Lwt.return (execute_command cmd)
          with
          | Yojson.Json_error msg ->
              Lwt.return (Error (ParseError ("Invalid JSON: " ^ msg)))
          | exn ->
              Lwt.return (Error (ParseError (Printexc.to_string exn)))

(* --- CLI argument parsing --- *)
let parse_args () =
  let argc = Array.length Sys.argv in
  if argc < 2 then begin
    Printf.eprintf "Usage: %s [OPTIONS] \"your command\"\n" Sys.argv.(0);
    Printf.eprintf "\nOptions:\n";
    Printf.eprintf "  -m, --model MODEL    Specify Ollama model (default: %s)\n"
      Config.default_model;
    Printf.eprintf "\nExamples:\n";
    Printf.eprintf "  %s \"list files in current directory\"\n" Sys.argv.(0);
    Printf.eprintf "  %s -m llama2 \"create a folder called test\"\n" Sys.argv.(0);
    exit 1
  end;

  let rec parse acc i =
    if i >= argc then List.rev acc
    else match Sys.argv.(i) with
    | "-m" | "--model" when i + 1 < argc ->
        parse (Sys.argv.(i + 1) :: acc) (i + 2)
    | arg -> parse (arg :: acc) (i + 1)
  in

  let args = parse [] 1 in
  match args with
  | model :: rest when List.length rest > 0 ->
      (model, String.concat " " rest)
  | prompt_parts ->
      (Config.default_model, String.concat " " prompt_parts)

(* --- Entry point --- *)
let () =
  let (model, prompt) = parse_args () in

  Printf.printf "🚀 Jarvis CLI Assistant\n";
  Printf.printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
  Printf.printf "Model: %s\n" model;
  Printf.printf "Prompt: %s\n\n" prompt;

  let result = Lwt_main.run (
    Lwt.catch
      (fun () -> process_request model prompt)
      (fun exn -> Lwt.return (Error (NetworkError (Printexc.to_string exn))))
  ) in

  match result with
  | Ok output ->
      Printf.printf "✅ Result:\n%s\n" output;
      exit 0
  | Error err ->
      Printf.eprintf "❌ Error: %s\n" (error_to_string err);
      exit 1

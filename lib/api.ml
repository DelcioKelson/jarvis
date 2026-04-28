(** OpenAI-compatible API interaction module *)

open Lwt.Infix
open Yojson.Basic.Util

(** Input type for API requests *)
type input_type =
  | Command
  | Question

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

(** Build system prompt for the given input type *)
let system_prompt_for = function
  | Command ->
    "You are a Linux command-line assistant. Your task is to convert user requests into structured JSON commands.\n\
     If a path is not specified, assume the current working directory.\n\
     Available commands: ls, mkdir, echo, pwd, cat, head, tail, find, grep, wc, du, df, whoami, hostname, date, env.\n\
     Respond ONLY with valid JSON — no explanations, comments, or additional text.\n\n\
     Available Read-Only Commands:\n\
     - ls [path] — List directory contents\n\
     - pwd — Print working directory\n\
     - cat <path> — Display file contents\n\
     - head <path> [-n lines] — Display first lines of a file (default 10)\n\
     - tail <path> [-n lines] — Display last lines of a file (default 10)\n\
     - find <path> [-name pattern] — Search for files\n\
     - grep <pattern> <path> — Search for text patterns in files\n\
     - wc <path> — Count lines, words, and bytes in a file\n\
     - du [path] — Display disk usage\n\
     - df — Display disk space usage\n\
     - whoami — Display current user\n\
     - hostname — Display system hostname\n\
     - date — Display current date and time\n\
     - env [variable] — Display environment variables\n\
     - echo <text> — Print text\n\n\
     Write Commands:\n\
     - mkdir <path> — Create a new directory\n\n\
     Response format: {\"action\": \"<command>\", \"args\": {<command-specific args>}}\n\n\
     Examples:\n\
     - List current directory: {\"action\": \"ls\", \"args\": {\"path\": \".\"}}\n\
     - Show first 20 lines: {\"action\": \"head\", \"args\": {\"path\": \"file.txt\", \"lines\": 20}}\n\
     - Find .txt files: {\"action\": \"find\", \"args\": {\"path\": \".\", \"name\": \"*.txt\"}}\n\
     - Search for error: {\"action\": \"grep\", \"args\": {\"pattern\": \"error\", \"path\": \"app.log\"}}\n\
     - Create folder: {\"action\": \"mkdir\", \"args\": {\"path\": \"Documents\"}}\n\
     - Echo text: {\"action\": \"echo\", \"args\": {\"text\": \"Hello World!\"}}\n\
     - Show date: {\"action\": \"date\", \"args\": {}}\n\
     - Show pwd: {\"action\": \"pwd\", \"args\": {}}"
  | Question ->
    "You are a helpful assistant. Answer the user's question clearly and concisely in plain text. \
     Do not use markdown formatting unless specifically asked."

(** Call OpenAI-compatible API with timeout *)
let ask ?(model = Config.default_model) input_type prompt =
  if Config.api_key = "" then
    Lwt.return (Error (Error.ConnectionError "JARVIS_API_KEY is not set"))
  else
  let uri = Uri.of_string (Config.api_base_url ^ "/chat/completions") in
  let base_body = [
    ("model", `String model);
    ("stream", `Bool false);
    ("temperature", `Float 0.1);
    ("messages", `List [
      `Assoc [("role", `String "system"); ("content", `String (system_prompt_for input_type))];
      `Assoc [("role", `String "user"); ("content", `String prompt)]
    ])
  ] in
  let body_with_format = match input_type with
    | Command -> ("response_format", `Assoc [("type", `String "json_object")]) :: base_body
    | Question -> base_body
  in
  let body = `Assoc body_with_format |> Yojson.Basic.to_string in
  Utils.debug_log "Request body: %s" body;

  let headers = Cohttp.Header.of_list [
    ("Content-Type", "application/json");
    ("Authorization", "Bearer " ^ Config.api_key)
  ] in

  let request =
    Cohttp_lwt_unix.Client.post
      ~body:(Cohttp_lwt.Body.of_string body)
      ~headers
      uri
    >>= fun (resp, body) ->
    let status = Cohttp.Response.status resp in
    if Cohttp.Code.(is_success (code_of_status status)) then
      Cohttp_lwt.Body.to_string body >|= fun b ->
      (try
        Utils.debug_log "Raw API response: %s" b;
        let json = Yojson.Basic.from_string b in
        let choices = json |> member "choices" in
        (match choices with
        | `List (choice :: _) ->
            (match Utils.get_string_field (choice |> member "message") "content" with
            | Some content -> Ok content
            | None -> Error (Error.NetworkError "Response missing 'content' field"))
        | _ -> Error (Error.NetworkError "Response missing 'choices' field"))
      with exn ->
        Error (Error.NetworkError ("Failed to parse response: " ^ Printexc.to_string exn)))
    else
      Cohttp_lwt.Body.to_string body >>= fun err_body ->
      Utils.debug_log "HTTP error %d: %s" (Cohttp.Code.code_of_status status) err_body;
      Lwt.return (Error (Error.NetworkError
        (Printf.sprintf "HTTP %d: %s"
          (Cohttp.Code.code_of_status status) err_body)))
  in

  Lwt.pick [
    request;
    (Lwt_unix.sleep Config.request_timeout >>= fun () ->
     Lwt.return (Error Error.TimeoutError))
  ]

(** Main processing pipeline *)
let process input_type model prompt =
  ask ~model input_type prompt >>= function
  | Error err -> Lwt.return (Error err)
  | Ok reply ->
      match input_type with
      | Question -> Lwt.return (Ok reply)
      | Command ->
          match Utils.extract_json_block reply with
          | Error err -> Lwt.return (Error err)
          | Ok json_str ->
              Utils.debug_log "Extracted JSON: %s" json_str;
              (try
                let cmd_json = Yojson.Basic.from_string json_str in
                match Command.of_json cmd_json with
                | Error err -> Lwt.return (Error err)
                | Ok cmd -> Lwt.return (Executor.execute cmd)
              with exn ->
                Lwt.return (Error (Error.ParseError
                  (Printf.sprintf "Invalid JSON from model: %s" (Printexc.to_string exn)))))

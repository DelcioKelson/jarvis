(** Ollama API interaction module *)

open Lwt.Infix
open Yojson.Basic.Util

(** Input type for API requests *)
type input_type = 
  | Command 
  | Question

(** Call Ollama API with timeout *)
let ask ?(model=Config.default_model) input_type prompt =
  let uri = Uri.of_string (Config.ollama_base_url ^ "/api/chat") in
  let system_prompt = match input_type with
    | Command ->
      "You are a CLI assistant. Convert user requests into structured JSON commands. \
       Available commands: ls, mkdir, echo, pwd, cat. Respond ONLY with valid JSON."
    | Question ->
      "You are a helpful assistant. Answer the user's question in plain text."
  in
  (* Build body with format only for Command input type *)
  let base_body = [
    ("model", `String model);
    ("stream", `Bool false);
    ("messages", `List [
      `Assoc [("role", `String "system"); ("content", `String system_prompt)];
      `Assoc [("role", `String "user"); ("content", `String prompt)]
    ]);
    ("options", `Assoc [
      ("temperature", `Float 0.1);
      ("top_p", `Float 0.9);
      ("num_ctx", `Int Config.num_ctx);
      ("num_predict", `Int Config.num_predict);
      ("num_threads", `Int Config.num_threads)
    ])
  ] in
  let body_with_format = match input_type with
    | Command -> ("format", Command.format_json) :: base_body
    | Question -> base_body
  in
  let body = `Assoc body_with_format |> Yojson.Basic.to_string in

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
        Utils.debug_log "Raw API response: %s" b;
        let json = Yojson.Basic.from_string b in
        Utils.debug_log "Parsed API JSON successfully";
        match Utils.get_string_field (json |> member "message") "content" with
        | Some content ->
            Utils.debug_log "Extracted content from response";
            Ok content
        | None ->
            Utils.debug_log "Content field is missing or null";
            Error (Error.NetworkError "Response missing 'content' field")
      with exn ->
        Utils.debug_log "Exception parsing API response: %s" (Printexc.to_string exn);
        Error (Error.NetworkError ("Failed to parse response: " ^ Printexc.to_string exn))
    else
      Cohttp_lwt.Body.to_string body >>= fun err_body ->
      Utils.debug_log "HTTP error %d: %s" (Cohttp.Code.code_of_status status) err_body;
      Lwt.return (Error (Error.NetworkError
        (Printf.sprintf "HTTP %d: %s"
          (Cohttp.Code.code_of_status status) err_body)))
  in

  (* Add timeout *)
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
              let cmd_json = Yojson.Basic.from_string json_str in
              match Command.of_json cmd_json with
              | Error err -> Lwt.return (Error err)
              | Ok cmd -> Lwt.return (Executor.execute cmd)

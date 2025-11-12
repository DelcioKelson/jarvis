(** Command types and parsing for Jarvis *)

open Yojson.Basic.Util

(** Command types *)
type t =
  | Ls of string option
  | Mkdir of string
  | Echo of string
  | Pwd
  | Cat of string

(** JSON Schema for structured output *)
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

(** Parse command from JSON *)
let of_json json : (t, Error.error) result =
  try
    Utils.debug_log "Parsing command JSON: %s" (Yojson.Basic.to_string json);
    match Utils.get_required_string json "action" with
    | Error e ->
        Utils.debug_log "Failed to get action field";
        Error e
    | Ok action ->
        Utils.debug_log "Action: %s" action;
        let args = json |> member "args" in
        Utils.debug_log "Args: %s" (Yojson.Basic.to_string args);
        match action with
        | "ls" ->
            let path = Utils.get_string_field args "path" in
            Utils.debug_log "Ls command with path: %s"
              (Option.value path ~default:"<none>");
            Ok (Ls path)
        | "mkdir" ->
            (match Utils.get_required_string args "path" with
            | Ok path ->
                Utils.debug_log "Mkdir command with path: %s" path;
                Ok (Mkdir path)
            | Error e -> Error e)
        | "echo" ->
            (match Utils.get_required_string args "content" with
            | Ok content ->
                Utils.debug_log "Echo command with content: %s" content;
                Ok (Echo content)
            | Error e -> Error e)
        | "pwd" ->
            Utils.debug_log "Pwd command";
            Ok Pwd
        | "cat" ->
            (match Utils.get_required_string args "path" with
            | Ok path ->
                Utils.debug_log "Cat command with path: %s" path;
                Ok (Cat path)
            | Error e -> Error e)
        | unknown ->
            Utils.debug_log "Unknown action: %s" unknown;
            Error (Error.UnknownCommand unknown)
  with
  | Yojson.Basic.Util.Type_error (msg, _) ->
      Utils.debug_log "JSON type error: %s" msg;
      Error (Error.ParseError ("JSON type error: " ^ msg))
  | exn ->
      Utils.debug_log "Exception parsing command: %s" (Printexc.to_string exn);
      Error (Error.ParseError (Printexc.to_string exn))


(** Convert command to human-readable string *)
let to_string = function
  | Ls None -> "ls"
  | Ls (Some path) -> Printf.sprintf "ls %s" path
  | Mkdir path -> Printf.sprintf "mkdir %s" path
  | Echo text -> Printf.sprintf "echo \"%s\"" text
  | Pwd -> "pwd"
  | Cat path -> Printf.sprintf "cat %s" path
(** Command types and parsing for Jarvis *)

open Yojson.Basic.Util

(** Command types *)
type t =
  | Ls of string option
  | Mkdir of string
  | Echo of string
  | Pwd
  | Cat of string
  | Head of { path: string; lines: int option }
  | Tail of { path: string; lines: int option }
  | Find of { path: string; name: string option }
  | Grep of { pattern: string; path: string }
  | Wc of string
  | Du of string option
  | Df
  | Whoami
  | Hostname
  | Date
  | Env of string option

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
      ];
      (* cat *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "cat")]);
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
      (* pwd *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "pwd")]);
          ("args", `Assoc [("type", `String "object"); ("properties", `Assoc []); ("additionalProperties", `Bool false)])
        ]);
        ("required", `List [`String "action"; `String "args"])
      ];
      (* head *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "head")]);
          ("args", `Assoc [
            ("type", `String "object");
            ("properties", `Assoc [
              ("path", `Assoc [("type", `String "string")]);
              ("lines", `Assoc [("type", `String "integer")])
            ]);
            ("required", `List [`String "path"]);
            ("additionalProperties", `Bool false)
          ])
        ]);
        ("required", `List [`String "action"; `String "args"])
      ];
      (* tail *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "tail")]);
          ("args", `Assoc [
            ("type", `String "object");
            ("properties", `Assoc [
              ("path", `Assoc [("type", `String "string")]);
              ("lines", `Assoc [("type", `String "integer")])
            ]);
            ("required", `List [`String "path"]);
            ("additionalProperties", `Bool false)
          ])
        ]);
        ("required", `List [`String "action"; `String "args"])
      ];
      (* find *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "find")]);
          ("args", `Assoc [
            ("type", `String "object");
            ("properties", `Assoc [
              ("path", `Assoc [("type", `String "string")]);
              ("name", `Assoc [("type", `String "string")])
            ]);
            ("required", `List [`String "path"]);
            ("additionalProperties", `Bool false)
          ])
        ]);
        ("required", `List [`String "action"; `String "args"])
      ];
      (* grep *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "grep")]);
          ("args", `Assoc [
            ("type", `String "object");
            ("properties", `Assoc [
              ("pattern", `Assoc [("type", `String "string")]);
              ("path", `Assoc [("type", `String "string")])
            ]);
            ("required", `List [`String "pattern"; `String "path"]);
            ("additionalProperties", `Bool false)
          ])
        ]);
        ("required", `List [`String "action"; `String "args"])
      ];
      (* wc *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "wc")]);
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
      (* du *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "du")]);
          ("args", `Assoc [
            ("type", `String "object");
            ("properties", `Assoc [
              ("path", `Assoc [("type", `String "string")])
            ]);
            ("additionalProperties", `Bool false)
          ])
        ]);
        ("required", `List [`String "action"; `String "args"])
      ];
      (* df *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "df")]);
          ("args", `Assoc [("type", `String "object"); ("properties", `Assoc []); ("additionalProperties", `Bool false)])
        ]);
        ("required", `List [`String "action"; `String "args"])
      ];
      (* whoami *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "whoami")]);
          ("args", `Assoc [("type", `String "object"); ("properties", `Assoc []); ("additionalProperties", `Bool false)])
        ]);
        ("required", `List [`String "action"; `String "args"])
      ];
      (* hostname *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "hostname")]);
          ("args", `Assoc [("type", `String "object"); ("properties", `Assoc []); ("additionalProperties", `Bool false)])
        ]);
        ("required", `List [`String "action"; `String "args"])
      ];
      (* date *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "date")]);
          ("args", `Assoc [("type", `String "object"); ("properties", `Assoc []); ("additionalProperties", `Bool false)])
        ]);
        ("required", `List [`String "action"; `String "args"])
      ];
      (* env *)
      `Assoc [
        ("properties", `Assoc [
          ("action", `Assoc [("const", `String "env")]);
          ("args", `Assoc [
            ("type", `String "object");
            ("properties", `Assoc [
              ("variable", `Assoc [("type", `String "string")])
            ]);
            ("additionalProperties", `Bool false)
          ])
        ]);
        ("required", `List [`String "action"; `String "args"])
      ]
  ])]

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
            (* Try "text" first (matches schema), fall back to "content" for compat *)
            let text_result =
              match Utils.get_string_field args "text" with
              | Some t -> Ok t
              | None -> Utils.get_required_string args "content"
            in
            (match text_result with
            | Ok text ->
                Utils.debug_log "Echo command with text: %s" text;
                Ok (Echo text)
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
        | "head" ->
            (match Utils.get_required_string args "path" with
            | Ok path ->
                let lines = 
                  try Some (args |> member "lines" |> to_int)
                  with _ -> None
                in
                Utils.debug_log "Head command with path: %s, lines: %s" path
                  (Option.value (Option.map string_of_int lines) ~default:"default");
                Ok (Head { path; lines })
            | Error e -> Error e)
        | "tail" ->
            (match Utils.get_required_string args "path" with
            | Ok path ->
                let lines = 
                  try Some (args |> member "lines" |> to_int)
                  with _ -> None
                in
                Utils.debug_log "Tail command with path: %s, lines: %s" path
                  (Option.value (Option.map string_of_int lines) ~default:"default");
                Ok (Tail { path; lines })
            | Error e -> Error e)
        | "find" ->
            (match Utils.get_required_string args "path" with
            | Ok path ->
                let name = Utils.get_string_field args "name" in
                Utils.debug_log "Find command with path: %s, name: %s" path
                  (Option.value name ~default:"*");
                Ok (Find { path; name })
            | Error e -> Error e)
        | "grep" ->
            (match Utils.get_required_string args "pattern" with
            | Ok pattern ->
                (match Utils.get_required_string args "path" with
                | Ok path ->
                    Utils.debug_log "Grep command with pattern: %s, path: %s" pattern path;
                    Ok (Grep { pattern; path })
                | Error e -> Error e)
            | Error e -> Error e)
        | "wc" ->
            (match Utils.get_required_string args "path" with
            | Ok path ->
                Utils.debug_log "Wc command with path: %s" path;
                Ok (Wc path)
            | Error e -> Error e)
        | "du" ->
            let path = Utils.get_string_field args "path" in
            Utils.debug_log "Du command with path: %s"
              (Option.value path ~default:".");
            Ok (Du path)
        | "df" ->
            Utils.debug_log "Df command";
            Ok Df
        | "whoami" ->
            Utils.debug_log "Whoami command";
            Ok Whoami
        | "hostname" ->
            Utils.debug_log "Hostname command";
            Ok Hostname
        | "date" ->
            Utils.debug_log "Date command";
            Ok Date
        | "env" ->
            let variable = Utils.get_string_field args "variable" in
            Utils.debug_log "Env command with variable: %s"
              (Option.value variable ~default:"all");
            Ok (Env variable)
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


let to_string = function
  | Ls None -> "ls"
  | Ls (Some path) -> Printf.sprintf "ls %s" path
  | Mkdir path -> Printf.sprintf "mkdir %s" path
  | Echo text -> Printf.sprintf "echo \"%s\"" text
  | Pwd -> "pwd"
  | Cat path -> Printf.sprintf "cat %s" path
  | Head { path; lines = None } -> Printf.sprintf "head %s" path
  | Head { path; lines = Some n } -> Printf.sprintf "head -n %d %s" n path
  | Tail { path; lines = None } -> Printf.sprintf "tail %s" path
  | Tail { path; lines = Some n } -> Printf.sprintf "tail -n %d %s" n path
  | Find { path; name = None } -> Printf.sprintf "find %s" path
  | Find { path; name = Some n } -> Printf.sprintf "find %s -name '%s'" path n
  | Grep { pattern; path } -> Printf.sprintf "grep '%s' %s" pattern path
  | Wc path -> Printf.sprintf "wc %s" path
  | Du None -> "du"
  | Du (Some path) -> Printf.sprintf "du %s" path
  | Df -> "df"
  | Whoami -> "whoami"
  | Hostname -> "hostname"
  | Date -> "date"
  | Env None -> "env"
  | Env (Some var) -> Printf.sprintf "echo $%s" var
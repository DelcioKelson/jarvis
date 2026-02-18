(** Configuration module for Jarvis CLI Assistant *)

let version = "2.0.0"

(** Load .env file from a given path if it exists *)
let load_env_file path =
  if Sys.file_exists path then
    try
      let ic = open_in path in
      let rec read_lines acc =
        try
          let line = input_line ic in
          let line = String.trim line in
          if line = "" || (String.length line > 0 && line.[0] = '#') then
            read_lines acc
          else
            (try
              let idx = String.index line '=' in
              let key = String.trim (String.sub line 0 idx) in
              let raw_value = String.trim (String.sub line (idx + 1) (String.length line - idx - 1)) in
              (* Strip surrounding quotes *)
              let value =
                let len = String.length raw_value in
                if len >= 2 &&
                   ((raw_value.[0] = '"' && raw_value.[len - 1] = '"') ||
                    (raw_value.[0] = '\'' && raw_value.[len - 1] = '\'')) then
                  String.sub raw_value 1 (len - 2)
                else raw_value
              in
              read_lines ((key, value) :: acc)
            with Not_found -> read_lines acc)
        with End_of_file ->
          close_in ic;
          List.rev acc
      in
      read_lines []
    with _ -> []
  else []

(** Env vars loaded from config files (project .env first, then ~/.jarvis.env) *)
let env_vars =
  let home_env =
    match Sys.getenv_opt "HOME" with
    | Some home -> load_env_file (Filename.concat home ".jarvis.env")
    | None -> []
  in
  let local_env = load_env_file ".env" in
  (* local .env overrides ~/.jarvis.env *)
  local_env @ home_env

let get_config key default_value =
  (* Priority: 1. System env var, 2. .env file (project), 3. ~/.jarvis.env, 4. default *)
  match Sys.getenv_opt key with
  | Some v -> v
  | None ->
      match List.assoc_opt key env_vars with
      | Some v -> v
      | None -> default_value

let ollama_base_url = get_config "OLLAMA_BASE_URL" "http://localhost:11434"

let default_model = get_config "JARVIS_MODEL" "qwen2.5:0.5b"

let request_timeout =
  let t = get_config "JARVIS_TIMEOUT" "30.0" in
  try float_of_string t with _ -> 30.0

let debug =
  let d = get_config "JARVIS_DEBUG" "false" in
  ref (d = "true" || d = "1")

let num_ctx =
  let n = get_config "JARVIS_NUM_CTX" "512" in
  try int_of_string n with _ -> 512

let num_predict =
  let n = get_config "JARVIS_NUM_PREDICT" "256" in
  try int_of_string n with _ -> 256

let num_threads =
  let n = get_config "JARVIS_NUM_THREADS" "4" in
  try int_of_string n with _ -> 4

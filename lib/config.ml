(** Configuration module for Jarvis CLI Assistant *)

(** Load .env file if it exists *)
let load_env_file () =
  let env_file = ".env"
  in
  if Sys.file_exists env_file then
    try
      let ic = open_in env_file in
      let rec read_lines acc =
        try
          let line = input_line ic in
          let line = String.trim line in
          (* Skip empty lines and comments *)
          if line = "" || String.length line > 0 && line.[0] = '#' then
            read_lines acc
          else
            (* Parse KEY=VALUE *)
            try
              let idx = String.index line '=' in
              let key = String.trim (String.sub line 0 idx) in
              let value = String.trim (String.sub line (idx + 1) (String.length line - idx - 1)) in
              read_lines ((key, value) :: acc)
            with Not_found -> read_lines acc
        with End_of_file ->
          close_in ic;
          List.rev acc
      in
      read_lines []
    with _ -> []
  else []

let env_vars = load_env_file ()

let get_config key default_value =
  (* Priority: 1. System env var, 2. .env file, 3. default *)
  match Sys.getenv_opt key with
  | Some v -> v
  | None ->
      match List.assoc_opt key env_vars with
      | Some v -> v
      | None -> default_value

let ollama_base_url = get_config "OLLAMA_BASE_URL" "http://localhost:11434"

let default_model = get_config "JARVIS_MODEL" "qwen2.5:0.5b"

let request_timeout = 
  let t = get_config "JARVIS_TIMEOUT" "10.0" in
  try float_of_string t with _ -> 10.0

let debug = 
  let d = get_config "JARVIS_DEBUG" "false" in
  ref (d = "true" || d = "1")

let num_ctx = 
  let n = get_config "JARVIS_NUM_CTX" "512" in
  try int_of_string n with _ -> 512

let num_predict = 
  let n = get_config "JARVIS_NUM_PREDICT" "128" in
  try int_of_string n with _ -> 128

let num_threads = 
  let n = get_config "JARVIS_NUM_THREADS" "12" in
  try int_of_string n with _ -> 12

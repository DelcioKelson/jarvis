(** Configuration module for Jarvis CLI Assistant *)

let ollama_base_url = "http://localhost:11434"
let default_model = "qwen2.5:0.5b"
let request_timeout = 10.0 (* seconds *)
let debug = ref false (* Set to false to disable debug output *)

let num_ctx = 512
let num_predict = 128
let num_threads = 12

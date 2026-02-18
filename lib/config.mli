(** Configuration module for Jarvis CLI Assistant
    
    Configuration is loaded in the following priority order:
    1. System environment variables
    2. ~/.jarvis.env file
    3. Default values
*)

val ollama_base_url : string
(** Base URL for Ollama API. Can be set via OLLAMA_BASE_URL. Default: http://localhost:11434 *)

val default_model : string
(** Default model to use for queries. Can be set via JARVIS_MODEL env var. Default: qwen2.5:0.5b *)

val request_timeout : float
(** Request timeout in seconds. Can be set via JARVIS_TIMEOUT env var. Default: 10.0 *)

val debug : bool ref
(** Debug flag. Can be set via JARVIS_DEBUG env var (true/1). Default: false *)

val num_ctx : int
(** Context size. Can be set via JARVIS_NUM_CTX env var. Default: 512 *)

val num_predict : int
(** Number of tokens to predict. Can be set via JARVIS_NUM_PREDICT env var. Default: 128 *)

val num_threads : int
(** Number of threads to use. Can be set via JARVIS_NUM_THREADS env var. Default: 12 *)

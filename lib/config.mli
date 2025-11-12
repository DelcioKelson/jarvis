(** Configuration module for Jarvis CLI Assistant *)

val ollama_base_url : string
(** Base URL for Ollama API *)

val default_model : string
(** Default model to use for queries *)

val request_timeout : float
(** Request timeout in seconds *)

val debug : bool ref
(** Debug flag - set to true to enable debug output *)

val num_ctx : int
(** Context size *)

val num_predict : int
(** Number of tokens to predict *)

val num_threads : int
(** Number of threads to use *)

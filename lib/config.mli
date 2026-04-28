(** Configuration module for Jarvis CLI Assistant
    
    Configuration is loaded in the following priority order:
    1. System environment variables
    2. Project-local .env file
    3. ~/.config/jarvis/config.env file
    4. ~/.jarvis.env file
    5. Default values
*)

val version : string
(** Current version of Jarvis *)

val api_base_url : string
(** Base URL for the OpenAI-compatible API. Can be set via JARVIS_API_BASE_URL. Default: https://api.groq.com/openai/v1 *)

val api_key : string
(** API key for the LLM provider. Must be set via JARVIS_API_KEY. *)

val default_model : string
(** Default model to use for queries. Can be set via JARVIS_MODEL env var. Default: gpt-4o-mini *)

val request_timeout : float
(** Request timeout in seconds. Can be set via JARVIS_TIMEOUT env var. Default: 30.0 *)

val debug : bool ref
(** Debug flag. Can be set via JARVIS_DEBUG env var (true/1). Default: false *)

(** OpenAI-compatible API interaction module *)

(** Input type for API requests *)
type input_type =
  | Command
  | Question

val health_check : unit -> (unit, Error.error) result Lwt.t
(** Check if the API endpoint is reachable and the API key is set. *)

val ask : ?model:string -> input_type -> string -> (string, Error.error) result Lwt.t
(** Call Ollama API with the given input type and prompt *)

val process : input_type -> string -> string -> (string, Error.error) result Lwt.t
(** Main processing pipeline: call API and execute command if needed *)

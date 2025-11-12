(** Command execution logic for Jarvis *)

val execute : Command.t -> (string, Error.error) result
(** Execute a command safely and return the result *)

(** Jarvis - AI-powered CLI assistant using Ollama *)

(** {1 Modules} *)

module Config : module type of Config
(** Configuration settings *)

module Error : module type of Error
(** Error types and handling *)

module Utils : module type of Utils
(** Utility functions *)

module Command : module type of Command
(** Command types and parsing *)

module Executor : module type of Executor
(** Command execution *)

module Api : module type of Api
(** Ollama API interaction *)

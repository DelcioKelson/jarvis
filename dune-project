(lang dune 3.10)
(name jarvis)
(version 2.0.0)
(generate_opam_files true)

(source (github DelcioKelson/jarvis))
(authors "Jarvis Team")
(maintainers "Jarvis Team")
(license MIT)

(package
 (name jarvis)
 (synopsis "AI-powered CLI assistant using Ollama")
 (description "Jarvis is a CLI assistant that uses Ollama to execute commands and answer questions through natural language. Features interactive REPL mode, colored output, and type-safe command execution.")
 (depends
  (ocaml (>= 4.14))
  (dune (>= 3.10))
  (cohttp-lwt-unix (>= 5.0))
  (yojson (>= 2.0))
  (bos (>= 0.2))
  (lwt (>= 5.6))))

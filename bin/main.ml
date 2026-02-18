(** Jarvis — AI-powered CLI Assistant
    Main entry point with CLI argument parsing and interactive REPL *)

open Jarvis

(* ── CLI Types ──────────────────────────────────────────────────── *)

type mode =
  | CommandMode of string
  | QuestionMode of string
  | InteractiveMode
  | ShowHelp
  | ShowVersion

type cli_opts = {
  mode : mode;
  model : string;
  debug : bool;
}

(* ── Help Text ──────────────────────────────────────────────────── *)

let usage_text = Printf.sprintf
{|%s — AI-powered CLI Assistant (v%s)

%s
  jarvis [OPTIONS] <MODE> "your input"

%s
  -c, --command "text"    Execute a system command from natural language
  -q, --question "text"   Ask a question and get an answer
  -i, --interactive       Start interactive REPL mode

%s
  -m, --model <name>      Override the Ollama model (default: %s)
  -d, --debug             Enable debug output
  -h, --help              Show this help message
  -v, --version           Show version

%s
  jarvis -q "What is the capital of France?"
  jarvis -c "list files in current directory"
  jarvis -c "create a directory called test"
  jarvis -m llama3 -c "show disk usage"
  jarvis -i
  jarvis --interactive --model qwen2.5:0.5b

%s
  Config is loaded from (in priority order):
    1. Environment variables
    2. .env file in current directory
    3. ~/.jarvis.env

  Supported env vars:
    OLLAMA_BASE_URL   (default: http://localhost:11434)
    JARVIS_MODEL      (default: %s)
    JARVIS_TIMEOUT    (default: 30.0)
    JARVIS_NUM_CTX    (default: 512)
    JARVIS_NUM_PREDICT (default: 256)
    JARVIS_NUM_THREADS (default: 4)
    JARVIS_DEBUG      (default: false)
|}
  (Utils.bold "jarvis") Config.version
  (Utils.bold "USAGE")
  (Utils.bold "MODES")
  (Utils.bold "OPTIONS")
  Config.default_model
  (Utils.bold "EXAMPLES")
  (Utils.bold "CONFIGURATION")
  Config.default_model

(* ── Argument Parsing ───────────────────────────────────────────── *)

let parse_args () : cli_opts =
  let argc = Array.length Sys.argv in
  if argc < 2 then begin
    Printf.eprintf "%s\n" usage_text;
    exit 1
  end;

  let model = ref Config.default_model in
  let debug = ref false in
  let mode = ref None in
  let i = ref 1 in

  while !i < argc do
    (match Sys.argv.(!i) with
    | "-h" | "--help" ->
        mode := Some ShowHelp
    | "-v" | "--version" ->
        mode := Some ShowVersion
    | "-d" | "--debug" ->
        debug := true
    | "-m" | "--model" ->
        if !i + 1 < argc then begin
          incr i;
          model := Sys.argv.(!i)
        end else begin
          Utils.print_error "Missing value for --model";
          exit 1
        end
    | "-c" | "--command" ->
        if !i + 1 < argc then begin
          (* Collect all remaining args as the prompt *)
          incr i;
          let parts = ref [] in
          while !i < argc do
            parts := Sys.argv.(!i) :: !parts;
            incr i
          done;
          mode := Some (CommandMode (String.concat " " (List.rev !parts)))
        end else begin
          Utils.print_error "Missing input for --command";
          exit 1
        end
    | "-q" | "--question" ->
        if !i + 1 < argc then begin
          incr i;
          let parts = ref [] in
          while !i < argc do
            parts := Sys.argv.(!i) :: !parts;
            incr i
          done;
          mode := Some (QuestionMode (String.concat " " (List.rev !parts)))
        end else begin
          Utils.print_error "Missing input for --question";
          exit 1
        end
    | "-i" | "--interactive" ->
        mode := Some InteractiveMode
    | arg ->
        Utils.print_error (Printf.sprintf "Unknown argument: %s" arg);
        Printf.eprintf "\nRun 'jarvis --help' for usage.\n";
        exit 1);
    incr i
  done;

  match !mode with
  | None ->
      Printf.eprintf "%s\n" usage_text;
      exit 1
  | Some m ->
      { mode = m; model = !model; debug = !debug }

(* ── Process a single request ───────────────────────────────────── *)

let process_request input_type model prompt =
  Lwt_main.run (
    Lwt.catch
      (fun () -> Api.process input_type model prompt)
      (fun exn ->
        Lwt.return (Error (Error.ConnectionError (Printexc.to_string exn))))
  )

(* ── Interactive REPL ───────────────────────────────────────────── *)

let run_interactive model =
  Printf.printf "\n%s\n" (Utils.bold_cyan "╔══════════════════════════════════════════════╗");
  Printf.printf "%s\n"   (Utils.bold_cyan "║   Jarvis Interactive Mode                    ║");
  Printf.printf "%s\n\n" (Utils.bold_cyan "╚══════════════════════════════════════════════╝");
  Utils.print_info (Printf.sprintf "Model: %s" (Utils.yellow model));
  Utils.print_info "Prefix with '/' for commands, or just type a question.";
  Utils.print_info "Type 'exit', 'quit', or Ctrl-D to leave.\n";

  let running = ref true in
  while !running do
    Printf.printf "%s " (Utils.bold_green "jarvis>");
    flush stdout;
    match In_channel.input_line stdin with
    | None ->
        (* Ctrl-D / EOF *)
        Printf.printf "\n";
        Utils.print_info "Goodbye!";
        running := false
    | Some line ->
        let input = String.trim line in
        if input = "" then ()
        else if input = "exit" || input = "quit" then begin
          Utils.print_info "Goodbye!";
          running := false
        end
        else if input = "help" || input = "/help" then begin
          Printf.printf "\n%s\n" (Utils.bold "Interactive Commands:");
          Printf.printf "  %s         Ask a question directly\n" (Utils.cyan "<text>");
          Printf.printf "  %s    Execute a system command\n" (Utils.cyan "/c <text>");
          Printf.printf "  %s       Show current model\n" (Utils.cyan "/model");
          Printf.printf "  %s        Toggle debug mode\n" (Utils.cyan "/debug");
          Printf.printf "  %s         Clear the screen\n" (Utils.cyan "/clear");
          Printf.printf "  %s  Exit interactive mode\n\n" (Utils.cyan "exit|quit");
        end
        else if input = "/model" then
          Utils.print_info (Printf.sprintf "Current model: %s" (Utils.yellow model))
        else if input = "/debug" then begin
          Config.debug := not !(Config.debug);
          Utils.print_info (Printf.sprintf "Debug mode: %s"
            (if !(Config.debug) then Utils.green "on" else Utils.red "off"))
        end
        else if input = "/clear" then
          ignore (Sys.command "clear")
        else begin
          let (input_type, prompt) =
            if String.length input > 3 && String.sub input 0 3 = "/c " then
              (Api.Command, String.trim (String.sub input 3 (String.length input - 3)))
            else
              (Api.Question, input)
          in
          Printf.printf "%s\n" (Utils.dim "Thinking...");
          flush stdout;
          match process_request input_type model prompt with
          | Ok output ->
              Utils.print_jarvis_response output
          | Error err ->
              Utils.print_error (Error.to_string err)
        end
  done

(* ── Entry Point ────────────────────────────────────────────────── *)

let () =
  let opts = parse_args () in

  (* Apply debug flag *)
  if opts.debug then Config.debug := true;

  match opts.mode with
  | ShowHelp ->
      Printf.printf "%s\n" usage_text;
      exit 0
  | ShowVersion ->
      Printf.printf "jarvis %s\n" Config.version;
      exit 0
  | InteractiveMode ->
      (* Health check before starting interactive mode *)
      (match Lwt_main.run (Api.health_check ()) with
      | Ok () ->
          Utils.debug_log "Ollama is reachable";
          run_interactive opts.model
      | Error err ->
          Utils.print_error (Error.to_string err);
          exit (Error.exit_code err))
  | CommandMode prompt ->
      (match process_request Api.Command opts.model prompt with
      | Ok output ->
          Utils.print_jarvis_response output;
          exit 0
      | Error err ->
          Utils.print_error (Error.to_string err);
          exit (Error.exit_code err))
  | QuestionMode prompt ->
      (match process_request Api.Question opts.model prompt with
      | Ok output ->
          Utils.print_jarvis_response output;
          exit 0
      | Error err ->
          Utils.print_error (Error.to_string err);
          exit (Error.exit_code err))

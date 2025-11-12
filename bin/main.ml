(** Main CLI entry point for Jarvis *)

open Jarvis

(** Parse command line arguments *)
let parse_args () =
  let argc = Array.length Sys.argv in
  if argc < 3 then begin
    Printf.eprintf "Usage: %s -q|-c [OPTIONS] \"your input\"\n" Sys.argv.(0);
    exit 1
  end;

  let input_type =
    match Sys.argv.(1) with
    | "-c" -> Api.Command
    | "-q" -> Api.Question
    | _ ->
        Printf.eprintf "❌ First argument must be -c (command) or -q (question)\n";
        exit 1
  in

  let rec parse_model i acc =
    if i >= argc then List.rev acc
    else match Sys.argv.(i) with
      | "-m" | "--model" when i + 1 < argc ->
          parse_model (i + 2) (Sys.argv.(i + 1) :: acc)
      | arg -> parse_model (i + 1) (arg :: acc)
  in

  let args = parse_model 2 [] in
  let model = Config.default_model in
  let prompt = String.concat " " (List.filter (fun s -> s <> model) args) in

  (input_type, model, prompt)

(** Entry point *)
let () =
  let (input_type, model, prompt) = parse_args () in

  let result = Lwt_main.run (
    Lwt.catch
      (fun () -> Api.process input_type model prompt)
      (fun exn -> Lwt.return (Error (Error.NetworkError (Printexc.to_string exn))))
  ) in

  match result with
  | Ok output ->
      Printf.printf " Jarvis:\n%s\n" output;
      exit 0
  | Error err ->
      Printf.eprintf "❌ Error: %s\n" (Error.to_string err);
      exit 1

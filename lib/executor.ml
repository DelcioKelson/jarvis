(** Command execution logic for Jarvis *)

(** Execute a command safely *)
let execute cmd : (string, Error.error) result =
  let () = Printf.printf "Executing command : %s\n" (Command.to_string cmd) in
  try
    match cmd with
    | Command.Ls path ->
        let p = Option.value path ~default:"." in
        let fpath = Fpath.v p in
        if not (Fpath.is_rel fpath || Fpath.is_abs fpath) then
          Error (Error.ExecutionError "Invalid path")
        else
          let cmd = Bos.Cmd.(v "ls" % "-lh" % Fpath.to_string fpath) in
          (match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
          | Ok (s, _) -> Ok s
          | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Mkdir path ->
        let dir = Fpath.v path in
        (match Bos.OS.Dir.create ~mode:0o755 dir with
        | Ok _ -> Ok (Printf.sprintf "📁 Directory created: %s\n" path)
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Echo text ->
        Ok (text ^ "\n")

    | Command.Pwd ->
        (match Bos.OS.Dir.current () with
        | Ok dir -> Ok (Fpath.to_string dir ^ "\n")
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Cat path ->
        let fpath = Fpath.v path in
        (match Bos.OS.File.read fpath with
        | Ok content -> Ok content
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Head { path; lines } ->
        let fpath = Fpath.v path in
        let n = Option.value lines ~default:10 in
        let cmd = Bos.Cmd.(v "head" % "-n" % string_of_int n % Fpath.to_string fpath) in
        (match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
        | Ok (s, _) -> Ok s
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Tail { path; lines } ->
        let fpath = Fpath.v path in
        let n = Option.value lines ~default:10 in
        let cmd = Bos.Cmd.(v "tail" % "-n" % string_of_int n % Fpath.to_string fpath) in
        (match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
        | Ok (s, _) -> Ok s
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Find { path; name } ->
        let fpath = Fpath.v path in
        let cmd = match name with
          | None -> Bos.Cmd.(v "find" % Fpath.to_string fpath)
          | Some n -> Bos.Cmd.(v "find" % Fpath.to_string fpath % "-name" % n)
        in
        (match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
        | Ok (s, _) -> Ok s
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Grep { pattern; path } ->
        let fpath = Fpath.v path in
        let cmd = Bos.Cmd.(v "grep" % pattern % Fpath.to_string fpath) in
        (match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
        | Ok (s, _) -> Ok s
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Wc path ->
        let fpath = Fpath.v path in
        let cmd = Bos.Cmd.(v "wc" % Fpath.to_string fpath) in
        (match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
        | Ok (s, _) -> Ok s
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Du path ->
        let p = Option.value path ~default:"." in
        let fpath = Fpath.v p in
        let cmd = Bos.Cmd.(v "du" % "-h" % Fpath.to_string fpath) in
        (match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
        | Ok (s, _) -> Ok s
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Df ->
        let cmd = Bos.Cmd.(v "df" % "-h") in
        (match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
        | Ok (s, _) -> Ok s
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Whoami ->
        let cmd = Bos.Cmd.(v "whoami") in
        (match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
        | Ok (s, _) -> Ok s
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Hostname ->
        let cmd = Bos.Cmd.(v "hostname") in
        (match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
        | Ok (s, _) -> Ok s
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Date ->
        let cmd = Bos.Cmd.(v "date") in
        (match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
        | Ok (s, _) -> Ok s
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Env variable ->
        (match variable with
        | None ->
            let cmd = Bos.Cmd.(v "env") in
            (match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
            | Ok (s, _) -> Ok s
            | Error (`Msg e) -> Error (Error.ExecutionError e))
        | Some var ->
            (match Bos.OS.Env.var var with
            | Some value -> Ok (Printf.sprintf "%s=%s\n" var value)
            | None -> Error (Error.ExecutionError (Printf.sprintf "Environment variable %s not set" var))))
  with
  | exn -> Error (Error.ExecutionError (Printexc.to_string exn))

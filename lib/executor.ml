(** Command execution logic for Jarvis *)

(** Helper to run a Bos command and return result *)
let run_cmd cmd =
  match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
  | Ok (s, _) -> Ok s
  | Error (`Msg e) -> Error (Error.ExecutionError e)

(** Execute a command safely *)
let execute cmd : (string, Error.error) result =
  Utils.print_command (Command.to_string cmd);
  try
    match cmd with
    | Command.Ls path ->
        let p = Option.value path ~default:"." in
        let fpath = Fpath.v p in
        if not (Fpath.is_rel fpath || Fpath.is_abs fpath) then
          Error (Error.ValidationError (Printf.sprintf "Invalid path: %s" p))
        else
          run_cmd Bos.Cmd.(v "ls" % "-lh" % Fpath.to_string fpath)

    | Command.Mkdir path ->
        let dir = Fpath.v path in
        (match Bos.OS.Dir.create ~mode:0o755 dir with
        | Ok true  -> Ok (Printf.sprintf "Directory created: %s" path)
        | Ok false -> Ok (Printf.sprintf "Directory already exists: %s" path)
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Echo text ->
        Ok text

    | Command.Pwd ->
        (match Bos.OS.Dir.current () with
        | Ok dir -> Ok (Fpath.to_string dir)
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Cat path ->
        let fpath = Fpath.v path in
        (match Bos.OS.File.read fpath with
        | Ok content -> Ok content
        | Error (`Msg e) -> Error (Error.ExecutionError e))

    | Command.Head { path; lines } ->
        let n = Option.value lines ~default:10 in
        run_cmd Bos.Cmd.(v "head" % "-n" % string_of_int n % path)

    | Command.Tail { path; lines } ->
        let n = Option.value lines ~default:10 in
        run_cmd Bos.Cmd.(v "tail" % "-n" % string_of_int n % path)

    | Command.Find { path; name } ->
        let cmd = match name with
          | None   -> Bos.Cmd.(v "find" % path)
          | Some n -> Bos.Cmd.(v "find" % path % "-name" % n)
        in
        run_cmd cmd

    | Command.Grep { pattern; path } ->
        run_cmd Bos.Cmd.(v "grep" % "--color=never" % pattern % path)

    | Command.Wc path ->
        run_cmd Bos.Cmd.(v "wc" % path)

    | Command.Du path ->
        let p = Option.value path ~default:"." in
        let fpath = Fpath.v p in
        run_cmd Bos.Cmd.(v "du" % "-sh" % Fpath.to_string fpath)

    | Command.Df ->
        run_cmd Bos.Cmd.(v "df" % "-h")

    | Command.Whoami ->
        run_cmd Bos.Cmd.(v "whoami")

    | Command.Hostname ->
        run_cmd Bos.Cmd.(v "hostname")

    | Command.Date ->
        run_cmd Bos.Cmd.(v "date")

    | Command.Env variable ->
        (match variable with
        | None -> run_cmd Bos.Cmd.(v "env")
        | Some var ->
            match Bos.OS.Env.var var with
            | Some value -> Ok (Printf.sprintf "%s=%s" var value)
            | None -> Error (Error.ExecutionError
                (Printf.sprintf "Environment variable '%s' is not set" var)))
  with
  | exn -> Error (Error.ExecutionError (Printexc.to_string exn))

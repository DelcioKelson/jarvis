(** Command execution logic for Jarvis *)

(** Execute a command safely *)
let execute cmd : (string, Error.error) result =
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
  with
  | exn -> Error (Error.ExecutionError (Printexc.to_string exn))

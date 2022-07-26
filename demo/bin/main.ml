open Core
open Async

let rec respond r w =
  match%bind Reader.read_line r with
  | `Eof -> return ()
  | `Ok line ->
      let%bind () = Writer.flushed w in
      Writer.write_line w (String.uppercase line) ;
      respond r w

let server () =
  let host_and_port =
    Tcp.Server.create ~on_handler_error:`Raise
      (Tcp.Where_to_listen.of_port 1729) (fun _ r w -> respond r w)
  in
  ignore host_and_port

let () =
  server () ;
  never_returns (Scheduler.go ())

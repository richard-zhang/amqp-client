open Amqp_client_lwt
open Lwt.Syntax

let message () =
  let args = Sys.argv in
  let mes = if Array.length args > 1 then args.(1) else "Hello, World!" in
  Message.make ~delivery_mode:2 mes

let main () =
  let* conn = Connection.connect ~id:"sender" "localhost" in
  let* chan = Connection.open_channel ~id:"test" Channel.no_confirm conn in
  let* queue = Queue.declare chan ~auto_delete:false "hello" in
  let* _ = Queue.publish chan queue (message ()) in
  Lwt_log.info "[x] Send Hello, World!"

let () =
  Lwt_log_core.default :=
    Lwt_log.channel ~template:"$(date).$(milliseconds) [$(level)] $(message)"
      ~close_mode:`Keep ~channel:Lwt_io.stdout ();
  Lwt_log_core.add_rule "*" Lwt_log_core.Info;
  Lwt_main.run (main ())

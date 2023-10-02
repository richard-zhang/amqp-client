open Amqp_client_lwt
open Lwt.Syntax

let main () =
  let* conn = Connection.connect ~id:"sender" "localhost" in
  let* chan = Connection.open_channel ~id:"test" Channel.no_confirm conn in
  let* queue = Queue.declare chan ~auto_delete:true "hello" in
  let* _  = Queue.publish chan queue (Message.make "Hello, World!") in
  Lwt_log.info "[x] Sent Hello World!"

let () = 
Lwt_log_core.default :=
Lwt_log.channel ~template:"$(date).$(milliseconds) [$(level)] $(message)" ~close_mode:`Keep ~channel:Lwt_io.stdout ();
Lwt_log_core.add_rule "*" Lwt_log_core.Info;
Lwt_main.run (main ())
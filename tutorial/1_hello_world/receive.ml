open Amqp_client_lwt
open Lwt.Syntax
open Thread
let cb (message : Amqp_client_lwt.Message.t) =
  let body = snd message.message in
  Lwt_log.ign_info_f "received message %s" body


let main () =
  let* conn = Connection.connect ~id:"sender" "localhost" in
  let* chan = Connection.open_channel ~id:"test" Channel.no_confirm conn in
  let* queue = Queue.declare chan ~auto_delete:true "hello" in
  let* (_consumer, reader) = Queue.consume ~id:"replay_a" chan queue in
  Pipe.iter_without_pushback reader ~f:cb

let () = 
Lwt_log_core.default :=
Lwt_log.channel ~template:"$(date).$(milliseconds) [$(level)] $(message)" ~close_mode:`Keep ~channel:Lwt_io.stdout ();
Lwt_log_core.add_rule "*" Lwt_log_core.Info;
Lwt_main.run (main ())
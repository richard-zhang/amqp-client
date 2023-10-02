open Amqp_client_lwt
open Lwt.Syntax
open Thread

let lwt_cb chan (message : Amqp_client_lwt.Message.t) =
  let body = snd message.message in
  let*_ = Message.ack chan message in
  Lwt_log.info_f "received message %s" body

let cb chan message = Lwt.async (fun () -> lwt_cb chan message)

let main () =
  let id = "receive_logs" in 
  let* conn = Connection.connect ~id "localhost" in
  let* chan = Connection.open_channel ~id Channel.no_confirm conn in
  let* exchange = Exchange.declare chan Exchange.fanout_t "logs" in 
  let* queue = Queue.declare chan ~autogenerate:true ~auto_delete:true "" in
  let* _ = Queue.bind chan queue exchange () in
  let* _consumer, reader = Queue.consume ~id chan queue in
  Pipe.iter_without_pushback reader ~f:(cb chan)

let () =
  Lwt_log_core.default :=
    Lwt_log.channel ~template:"$(date).$(milliseconds) [$(level)] $(message)"
      ~close_mode:`Keep ~channel:Lwt_io.stdout ();
  Lwt_log_core.add_rule "*" Lwt_log_core.Info;
  Lwt_main.run (main ())
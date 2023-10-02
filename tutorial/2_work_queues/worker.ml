open Amqp_client_lwt
open Lwt.Syntax
open Thread

let lwt_cb chan (message : Amqp_client_lwt.Message.t) =
  let body = snd message.message in
  let count =
    String.fold_right (fun c acc -> if c = '.' then acc + 1 else acc) body 0
  in
  let* _ = Lwt_unix.sleep (float_of_int count) in
  let*_ = Message.ack chan message in
  Lwt_log.info_f "received message %s" body

let cb chan message = Lwt.async (fun () -> lwt_cb chan message)

let main () =
  let* conn = Connection.connect ~id:"sender" "localhost" in
  let* chan = Connection.open_channel ~id:"test" Channel.no_confirm conn in
  let* _ = Channel.set_prefetch ~count:1 chan in
  let* queue = Queue.declare chan ~auto_delete:true "hello" in
  let* _consumer, reader = Queue.consume ~id:"replay_a" chan queue in
  Pipe.iter_without_pushback reader ~f:(cb chan)

let () =
  Lwt_log_core.default :=
    Lwt_log.channel ~template:"$(date).$(milliseconds) [$(level)] $(message)"
      ~close_mode:`Keep ~channel:Lwt_io.stdout ();
  Lwt_log_core.add_rule "*" Lwt_log_core.Info;
  Lwt_main.run (main ())

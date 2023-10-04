open Amqp_client_lwt
open Lwt.Syntax

let publish message routing_key chan exchange =
  Exchange.publish chan exchange ~routing_key (Message.make message)

let main () = 
  let* conn = Connection.connect ~id:"producer" "localhost" in
  let* chan = Connection.open_channel ~id:"test" Channel.no_confirm conn in
  let* exchange = Exchange.declare chan Exchange.topic_t "topic.logs" in
  let routing_key = Sys.argv.(1) in
  let body = Sys.argv.(2) in
  let* _ = publish body routing_key chan exchange in
  Lwt_log.info_f "[x] Send %s to with routing_key %s" body routing_key

let () =
  Lwt_log_core.default :=
    Lwt_log.channel ~template:"$(date).$(milliseconds) [$(level)] $(message)"
      ~close_mode:`Keep ~channel:Lwt_io.stdout ();
  Lwt_log_core.add_rule "*" Lwt_log_core.Info;
  Lwt_main.run (main ())
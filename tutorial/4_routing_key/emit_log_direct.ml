open Amqp_client_lwt
open Lwt.Syntax

let publish message severity chan exchange =
  Exchange.publish chan exchange ~routing_key:severity (Message.make message)

let main () = 
  let* conn = Connection.connect ~id:"producer" "localhost" in
  let* chan = Connection.open_channel ~id:"test" Channel.no_confirm conn in
  let* exchange = Exchange.declare chan Exchange.direct_t "direct.logs" in
  let serverity = Sys.argv.(1) in
  let body = Sys.argv.(2) in
  let* _ = publish body serverity chan exchange in
  Lwt_log.info_f "[x] Send %s to with serverity %s" body serverity

let () =
  Lwt_log_core.default :=
    Lwt_log.channel ~template:"$(date).$(milliseconds) [$(level)] $(message)"
      ~close_mode:`Keep ~channel:Lwt_io.stdout ();
  Lwt_log_core.add_rule "*" Lwt_log_core.Info;
  Lwt_main.run (main ())
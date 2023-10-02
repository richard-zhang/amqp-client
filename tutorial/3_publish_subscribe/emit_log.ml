open Amqp_client_lwt
open Lwt.Syntax

let main () = 
  let* conn = Connection.connect ~id:"producer" "localhost" in
  let* chan = Connection.open_channel ~id:"test" Channel.no_confirm conn in
  let* exchange = Exchange.declare chan Exchange.fanout_t "logs" in
  let* _ = Exchange.publish chan exchange ~routing_key:"" (Message.make "Hello, World!") in
  Lwt_log.info "[x] Send Hello, World to fanout exchange"

let () =
  Lwt_log_core.default :=
    Lwt_log.channel ~template:"$(date).$(milliseconds) [$(level)] $(message)"
      ~close_mode:`Keep ~channel:Lwt_io.stdout ();
  Lwt_log_core.add_rule "*" Lwt_log_core.Info;
  Lwt_main.run (main ())
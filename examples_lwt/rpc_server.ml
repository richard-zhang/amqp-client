open Amqp_client_lwt
open Thread
open Lwt

let handler (h, s) =
  Lwt_log.info_f "Recieved request: %s" s >>= fun _ ->
  return (h, s)

let start =
  Connection.connect ~id:"fugmann" "localhost" >>= fun connection ->
  Lwt_log.info "Connection started" >>= fun _ ->
  Connection.open_channel ~id:"test" Channel.no_confirm connection >>= fun channel ->
  Lwt_log.info "Channel opened" >>= fun _ ->
  Queue.declare channel ~arguments:[Rpc.Server.queue_argument] "rpc.server.echo_reply" >>= fun queue ->
  Rpc.Server.start channel queue handler >>= fun _server ->
  Lwt_log.info "Listening for requsts" >>= fun _ ->
  return ()

let _ =
  Lwt_log_core.default :=
    Lwt_log.channel ~template:"$(date).$(milliseconds) [$(level)] $(message)" ~close_mode:`Keep ~channel:Lwt_io.stdout ();
  Lwt_log_core.add_rule "*" Lwt_log_core.Info;
  Scheduler.go ()

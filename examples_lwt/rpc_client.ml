open Amqp_client_lwt
open Thread
open Lwt

let rec request t i =
  let req = Printf.sprintf "Echo: %d" i in
  Rpc.Client.call ~ttl:1000 t Exchange.default ~routing_key:"rpc.server.echo_reply" ~headers:[] (Message.make (string_of_int i)) >>= fun res ->
  begin
    match res with
    | Some (_, rep) -> Lwt_log.info_f "%s == %s" req rep
    | None -> Lwt_log.info_f "%s: no reply" req
  end >>= fun _ ->
  request t (i+1)

let test =
  Connection.connect ~id:"fugmann" "localhost" >>= fun connection ->
  Lwt_log.info "Connection started" >>= fun _ ->
  (*
  Connection.open_channel ~id:"rpc_test" Channel.no_confirm connection >>= fun channel ->
  Queue.declare channel ~arguments:[Rpc.Server.queue_argument] "rpc.server.echo_reply" >>= fun _queue ->
  *)
  Rpc.Client.init ~id:"Test" connection >>= fun client ->
  request client 1

let _ =
  Lwt_log_core.default :=
    Lwt_log.channel ~template:"$(date).$(milliseconds) [$(level)] $(message)" ~close_mode:`Keep ~channel:Lwt_io.stdout ();
  Lwt_log_core.add_rule "*" Lwt_log_core.Info;
  Scheduler.go ()

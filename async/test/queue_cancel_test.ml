open Amqp
open Thread

let handler var { Message.message = (_, body); _ } = Ivar.fill var body; return ()

let test =
  Connection.connect ~id:"fugmann" "localhost" >>= fun connection ->
  Log.info "Connection started";
  Connection.open_channel ~id:"queue.test" Channel.no_confirm connection >>= fun channel ->
  Log.info "Channel opened";
  Queue.declare channel ~auto_delete:true "queue.test" >>= fun queue ->
  Log.info "Queue declared";
  (* Start consuming *)
  let cancelled = ref false in
  Queue.consume ~id:"consume_test" ~on_cancel:(fun () -> cancelled := true) channel queue >>= fun (_consumer, reader) ->
  Queue.publish channel queue (Message.make "Test") >>= fun `Ok ->
  Pipe.read reader >>= fun res ->
  assert (res <> `Eof);
  Log.info "Message read";

  (* Delete the queue *)
  Queue.delete channel queue >>= fun () ->
  Log.info "Queue deleted";
  Pipe.read reader >>= fun res ->
  assert (res = `Eof);
  assert (!cancelled);
  Log.info "Consumer cancelled";
  Channel.close channel >>= fun () ->
  Log.info "Channel closed";
  Connection.close connection >>| fun () ->
  Log.info "Connection closed";
  Scheduler.shutdown 0

let _ =
  Scheduler.go ()

let () = Printf.printf "Done\n"

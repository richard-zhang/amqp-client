open Amqp
open Thread

let uniq s =
  Printf.sprintf "%s_%d_%s" (Filename.basename Sys.argv.(0)) (Unix.getpid ()) s

let handler var { Message.message = (_, body); _ } = Ivar.fill var body; return ()

let declare ~channel name =
  let queue_name = uniq name in
  Queue.declare channel ~auto_delete:true queue_name >>= fun queue ->
  Log.info "Created queue: %s === %s" (Queue.name queue) queue_name;
  match Queue.name queue = queue_name with
  | false -> failwith (Printf.sprintf "Queue name mismatch: %s != %s" (Queue.name queue) queue_name)
  | true -> return queue

let test =
  Connection.connect ~id:(uniq "") "localhost" >>= fun connection ->
  Log.info "Connection started";
  Connection.open_channel ~id:(uniq "queue.test") Channel.no_confirm connection >>= fun channel ->
  Log.info "Channel opened";
  let queue_names = List.init 10 (fun i -> Printf.sprintf "queue.test_%d" i) in
  let queues = List.map (declare ~channel) queue_names in
  List.fold_left (fun acc queue -> acc >>= fun acc -> queue >>= fun queue -> return (queue :: acc)) (return []) queues >>= fun queues ->
  Log.info "Queues declared";
  List.fold_left (fun acc queue -> acc >>= fun () -> Queue.delete channel queue) (return ()) queues >>= fun () ->
  Log.info "Queues deleted";
  Channel.close channel >>= fun () ->
  Log.info "Channel closed";
  Connection.close connection >>| fun () ->
  Log.info "Connection closed";
  Scheduler.shutdown 0

let _ =
  Scheduler.go ()
let () = Printf.printf "Done\n"

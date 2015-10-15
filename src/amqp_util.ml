open Async.Std
open Amqp_types
open Amqp_protocol

let request0 (message_type, message_id, spec, _make, apply) =
  let write = write spec in
  fun channel msg ->
    let data =
      apply (write (Output.create ())) msg
    in
    Amqp_channel.write channel message_type message_id data

let cancel channel (_message_type, message_id, _spec, _make, _apply) =
  Amqp_channel.cancel_receive channel (Amqp_framing.Method, message_id)

let reply0 (message_type, message_id, spec, make, _apply) =
  let read = read spec in
  fun channel ->
    Amqp_channel.receive channel (message_type, message_id) |> Ivar.read >>= fun data ->
    Amqp_channel.cancel_receive channel (message_type, message_id);
    let resp = read make data in
    return resp

let request1 req_spec rep_spec =
  let req = request0 req_spec in
  let rep = reply0 rep_spec in
  fun channel msg ->
    req channel msg;
    rep channel

let reply1 req_spec rep_spec =
  let req = reply0 req_spec in
  let rep = request0 rep_spec in
  fun channel (handler : 'a -> 'b Deferred.t) ->
    req channel >>= handler >>= fun msg ->
    rep channel msg;
    return ()

let request2 req_spec rep_spec1 id1 rep_spec2 id2 =
  let req = request0 req_spec in
  let rep1 = reply0 rep_spec1 in
  let rep2 = reply0 rep_spec2 in
  fun channel msg ->
    req channel msg;
    let r1 = rep1 channel >>= fun a -> return (id1 a) in
    let r2 = rep2 channel >>= fun a -> return (id2 a) in
    let open Pervasives in
    Deferred.any [r1; r2] >>= fun a ->
    cancel channel rep_spec1;
    cancel channel rep_spec2;
    return a

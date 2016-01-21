(*
Module: Test_Pgpool
  Provides unit tests and examples for the <Pgpool> lense.
*)

module Test_Pgpool =

(* View: conf *)
let conf = "# pgpool config
listen_address = '*'
port = 9999

print_timestamp = on
log_min_messages = debug5
"

test Pgpool.lns get conf =
  { "#comment" = "pgpool config" }
  { "listen_address" = "*" }
  { "port" = "9999" }
  { }
  { "print_timestamp" = "on" }
  { "log_min_messages" = "debug5" }

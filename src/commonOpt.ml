(** This module provide support for common command line option to be used across
    multiple subcomand*)

open Cmdliner

let setter reference term =
  let set r t = r := t in
  Term.(const (set reference) $ term)

let add_option opt term =
  let g a () = a in
  Term.(const g $ term $ opt)

let add_options olist term = List.fold_left (Fun.flip add_option) term olist

(** Replaces Term.const but allow a unit terms (like the one generated by setter) to
    be evaluated before the function is called *)
let func_option opt func = add_option opt Term.(const func)

(** Same as func_option but with a list of unit terms *)
let func_options olist func = add_options olist Term.(const func)

let exits =
  let doc = "on external errors, (Parsing error, Typing error, ...)." in
  let doc2 = "on non-exception internal errors like assertion failed." in
  Term.exit_info ~doc 1 :: Term.exit_info ~doc:doc2 2 :: Term.default_exits

let arch =
  let doc = "Overrides the default architecture to use in isla" in
  let env = Arg.env_var "ISLA_ARCH" ~doc in
  let doc = "Architecture to be analysed" in
  Arg.(value & opt non_dir_file "aarch64.ir" & info ["a"; "arch"] ~env ~docv:"ARCH_IR" ~doc)

let isla_client_ref = ref "isla-client"

let isla_client =
  let doc = "Overrides the default isla position (named isla-client)" in
  let env = Arg.env_var "ISLA_CLIENT" ~doc in
  let doc = "isla-client location" in
  setter isla_client_ref
    Arg.(value & opt string "isla-client" & info ["isla"] ~env ~docv:"ISLA_CLIENT_PATH" ~doc)

(** The z3 command *)
let z3_ref = ref "z3"

(** The z3 option *)
let z3 =
  let doc = "Overrides the default z3 position" in
  let env = Arg.env_var "Z3_PATH" ~doc in
  let doc = "z3 location" in
  setter z3_ref Arg.(value & opt string "z3" & info ["z3"] ~env ~docv:"Z3_PATH" ~doc)

let quiet_ref = ref false

let quiet =
  let doc = "Remove all errors and warnings from the output" in
  Arg.(value & flag & info ["q"; "quiet"] ~doc)

let verbose =
  let doc = "Log more stuff. When set twice, output all debugging logs" in
  Arg.(value & flag_all & info ["v"; "verbose"] ~doc)

let infoopt : string list Term.t =
  let doc = "Set a precise OCaml module in info-logging mode" in
  Arg.(value & opt_all string [] & info ["info"] ~doc ~docv:"MODULE")

let debug =
  let doc = "Set a precise OCaml module in debug-logging mode" in
  Arg.(value & opt_all string [] & info ["debug"] ~doc ~docv:"MODULE")

let process_logs_opts quiet verbose info debug =
  if quiet then Logs.set_default_level Base;
  if quiet then quiet_ref := true;
  begin
    match verbose with
    | [] -> ()
    | [true] -> Logs.set_default_level Info
    | _ -> Logs.set_default_level Debug
  end;
  List.iter (fun name -> Logs.set_level name Info) info;
  List.iter (fun name -> Logs.set_level name Debug) debug

let logs_term = Term.(const process_logs_opts $ quiet $ verbose $ infoopt $ debug)

let comopts = [isla_client; z3; logs_term]

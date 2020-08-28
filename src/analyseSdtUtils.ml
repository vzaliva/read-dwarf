(** Finding sdt (DWARF simple-die-tree) subroutines by various predicates *)

open Logs.Logger (struct
  let str = __MODULE__
end)

let rec find_sdt_subroutine_subroutine (recurse : bool) (p : Dwarf.sdt_subroutine -> bool)
    (ss : Dwarf.sdt_subroutine) : Dwarf.sdt_subroutine list =
  if recurse then
    let sss1 =
      List.concat_map (find_sdt_subroutine_subroutine recurse p) ss.ss_subroutines
      @ List.concat_map (find_sdt_subroutine_lexical_block recurse p) ss.ss_lexical_blocks
    in
    if p ss then ss :: sss1 else sss1
  else if p ss then [ss]
  else []

and find_sdt_subroutine_lexical_block (recurse : bool) (p : Dwarf.sdt_subroutine -> bool)
    (lb : Dwarf.sdt_lexical_block) : Dwarf.sdt_subroutine list =
  let sss1 =
    List.concat_map (find_sdt_subroutine_subroutine recurse p) lb.slb_subroutines
    @ List.concat_map (find_sdt_subroutine_lexical_block recurse p) lb.slb_lexical_blocks
  in
  sss1

and find_sdt_subroutine_compilation_unit (recurse : bool) (p : Dwarf.sdt_subroutine -> bool)
    (cu : Dwarf.sdt_compilation_unit) : Dwarf.sdt_subroutine list =
  List.concat_map (find_sdt_subroutine_subroutine recurse p) cu.scu_subroutines

and find_sdt_subroutine_dwarf (recurse : bool) (p : Dwarf.sdt_subroutine -> bool)
    (d : Dwarf.sdt_dwarf) : Dwarf.sdt_subroutine list =
  List.concat_map (find_sdt_subroutine_compilation_unit recurse p) d.sd_compilation_units

let find_sdt_subroutine_by_name (recurse : bool) (sdt_d : Dwarf.sdt_dwarf) (s : string) :
    Dwarf.sdt_subroutine option =
  let p (ss : Dwarf.sdt_subroutine) = match ss.ss_name with None -> false | Some s' -> s' = s in
  match find_sdt_subroutine_dwarf recurse p sdt_d with
  | [] -> None
  | [ss] -> Some ss
  | _ -> fatal "find_sdt_subroutine_by_name for \"%s\" found multiple matching subroutines" s

let find_sdt_subroutine_by_entry_address (sdt_d : Dwarf.sdt_dwarf) addr :
    Dwarf.sdt_subroutine list =
  let p (ss : Dwarf.sdt_subroutine) =
    match ss.ss_entry_address with None -> false | Some addr' -> addr' = addr
  in
  match find_sdt_subroutine_dwarf true p sdt_d with
  | [] -> fatal "find_sdt_subroutine_by_entry_address found no matching subroutines"
  | sss -> sss

let address_of_subroutine_name (sdt_d : Dwarf.sdt_dwarf) (s : string) =
  match find_sdt_subroutine_by_name false sdt_d s with
  | None -> None
  | Some ss -> ss.ss_entry_address

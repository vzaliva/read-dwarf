(** This module provide sum manipulation functionality on top of typed expression {!ExpTyped.t}

    This provide a semantic view of sums as list of terms and conversion

*)

(** Split an expression as a list of terms. This function sees through +,- and extracts.

    Any expression [e] should have the same semantic meaning as [ExpTyped.sum (split e)].

    TODO I need to sort according to an arbitrary order to be able to compare reliably.
    This will probably be part of a more general simplifier work.*)
val split : ('v, 'm) ExpTyped.t -> ('v, 'm) ExpTyped.t list

(** Merge a list of terms into a sum expression.
    This is an upgrade of {!ExpTyped.sum} to allow empty lists.
    In the case of an empty list, a [0] of size [size] will be inserted instead. *)
val merge : size:int -> ('v, 'm) ExpTyped.t list -> ('v, 'm) ExpTyped.t

(** Add a [term] to a sum, This is the same, as using {!split}, then adding [term] to the list,
    then merging with {!ExpTyped.sum}*)
val add_term : term:('v, 'm) ExpTyped.t -> ('v, 'm) ExpTyped.t -> ('v, 'm) ExpTyped.t

(** Remove a [term] from a sum.
    Return [Some res] if successful and [None] otherwise. *)
val remove_term :
  equal:(('v, 'm) ExpTyped.t -> ('v, 'm) ExpTyped.t -> bool) ->
  term:('v, 'm) ExpTyped.t ->
  ('v, 'm) ExpTyped.t ->
  ('v, 'm) ExpTyped.t option

(** Same as {!remove_term} but if the [term] is not found, add the opposite
    ({!Ast.Bvneg}) to the sum*)
val smart_substract :
  equal:(('v, 'm) ExpTyped.t -> ('v, 'm) ExpTyped.t -> bool) ->
  term:('v, 'm) ExpTyped.t ->
  ('v, 'm) ExpTyped.t ->
  ('v, 'm) ExpTyped.t

(** Split away the concrete terms of the sum and the symbolic part.
    The symbolic part can be [None] if the expression was fully concrete.
    If the symbolic part is [Some e], then
    [not ]{!has_concrete_term}[ e] will hold.*)
val split_concrete : ('v, Ast.no) ExpTyped.t -> ('v, Ast.no) ExpTyped.t option * BitVec.t

(** Tells if an expression has a concrete term *)
val has_concrete_term : ('v, 'm) ExpTyped.t -> bool

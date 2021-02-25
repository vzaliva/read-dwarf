(*==================================================================================*)
(*  BSD 2-Clause License                                                            *)
(*                                                                                  *)
(*  Copyright (c) 2020-2021 Thibaut Pérami                                          *)
(*  Copyright (c) 2020-2021 Dhruv Makwana                                           *)
(*  Copyright (c) 2019-2021 Peter Sewell                                            *)
(*  All rights reserved.                                                            *)
(*                                                                                  *)
(*  This software was developed by the University of Cambridge Computer             *)
(*  Laboratory as part of the Rigorous Engineering of Mainstream Systems            *)
(*  (REMS) project.                                                                 *)
(*                                                                                  *)
(*  This project has been partly funded by EPSRC grant EP/K008528/1.                *)
(*  This project has received funding from the European Research Council            *)
(*  (ERC) under the European Union's Horizon 2020 research and innovation           *)
(*  programme (grant agreement No 789108, ERC Advanced Grant ELVER).                *)
(*  This project has been partly funded by an EPSRC Doctoral Training studentship.  *)
(*  This project has been partly funded by Google.                                  *)
(*                                                                                  *)
(*  Redistribution and use in source and binary forms, with or without              *)
(*  modification, are permitted provided that the following conditions              *)
(*  are met:                                                                        *)
(*  1. Redistributions of source code must retain the above copyright               *)
(*     notice, this list of conditions and the following disclaimer.                *)
(*  2. Redistributions in binary form must reproduce the above copyright            *)
(*     notice, this list of conditions and the following disclaimer in              *)
(*     the documentation and/or other materials provided with the                   *)
(*     distribution.                                                                *)
(*                                                                                  *)
(*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''              *)
(*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED               *)
(*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A                 *)
(*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR             *)
(*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,                    *)
(*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT                *)
(*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF                *)
(*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND             *)
(*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,              *)
(*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT              *)
(*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF              *)
(*  SUCH DAMAGE.                                                                    *)
(*                                                                                  *)
(*==================================================================================*)

(* All the boring code is here, no interesting stuff going on,
   It was all generated by VIM macros. *)

let rec ty : Base.ty -> 'a Ast.ty = function
  | Ty_Bool -> Ty_Bool
  | Ty_BitVec i -> Ty_BitVec i
  | Ty_Enum e -> Ty_Enum e
  | Ty_Array (t1, t2) -> Ty_Array (ty t1, ty t2)

let unop : Base.unop -> Ast.unop = function
  | Not -> Not
  | Bvnot -> Bvnot
  | Bvredand -> Bvredand
  | Bvredor -> Bvredor
  | Bvneg -> Bvneg
  | Extract (i, j) -> Extract (i, j)
  | ZeroExtend i -> ZeroExtend i
  | SignExtend i -> SignExtend i

let bvarith : Base.bvarith -> Ast.bvarith = function
  | Bvnand -> Bvnand
  | Bvnor -> Bvnor
  | Bvxnor -> Bvxnor
  | Bvsub -> Bvsub
  | Bvudiv -> Bvudiv
  | Bvudivi -> Bvudivi
  | Bvsdiv -> Bvsdiv
  | Bvsdivi -> Bvsdivi
  | Bvurem -> Bvurem
  | Bvsrem -> Bvsrem
  | Bvsmod -> Bvsmod
  | Bvshl -> Bvshl
  | Bvlshr -> Bvlshr
  | Bvashr -> Bvashr

let bvcomp : Base.bvcomp -> Ast.bvcomp = function
  | Bvult -> Bvult
  | Bvslt -> Bvslt
  | Bvule -> Bvule
  | Bvsle -> Bvsle
  | Bvuge -> Bvuge
  | Bvsge -> Bvsge
  | Bvugt -> Bvugt
  | Bvsgt -> Bvsgt

let bvmanyarith : Base.bvmanyarith -> Ast.bvmanyarith = function
  | Bvand -> Bvand
  | Bvor -> Bvor
  | Bvxor -> Bvxor
  | Bvadd -> Bvadd
  | Bvmul -> Bvmul

let binop : Base.binop -> 'm Ast.binop = function
  | Eq -> Eq
  | Bvarith b -> Bvarith (bvarith b)
  | Bvcomp b -> Bvcomp (bvcomp b)

let manyop : Base.manyop -> Ast.manyop = function
  | And -> And
  | Or -> Or
  | Bvmanyarith b -> Bvmanyarith (bvmanyarith b)
  | Concat -> Concat

let direct_exp_no_var (conv : 'a Base.exp -> ('a, 'v, 'b, 'm) Ast.exp) :
    'a Base.exp -> ('a, 'v, 'b, 'm) Ast.exp = function
  | Bits (b, a) -> Bits (BitVec.of_smt b, a)
  | Bool (b, a) -> Bool (b, a)
  | Enum (e, a) -> Enum (e, a)
  | Unop (u, e, a) -> Unop (unop u, conv e, a)
  | Binop (b, e, e', a) -> Binop (binop b, conv e, conv e', a)
  | Manyop (m, el, a) -> Manyop (manyop m, List.map conv el, a)
  | Ite (c, e, e', a) -> Ite (conv c, conv e, conv e', a)
  | Var (_, _) -> failwith "var in direct_exp_no_var"

let rec exp_var_conv (vconv : int -> 'v) : 'a Base.exp -> ('a, 'v, 'b, 'm) Ast.exp = function
  | Var (i, a) -> Var (vconv i, a)
  | e -> direct_exp_no_var (exp_var_conv vconv) e

let exp e = exp_var_conv Fun.id e

(** Convert an expression from isla to Ast but using a var-to-exp conversion function *)
let rec exp_var_subst (vconv : int -> 'a -> ('a, 'v, 'b, 'm) Ast.exp) :
    'a Base.exp -> ('a, 'v, 'b, 'm) Ast.exp = function
  | Var (i, a) -> vconv i a
  | e -> direct_exp_no_var (exp_var_subst vconv) e

(** Convert directly from an untyped isla expression to an {!Exp.Typed} by
    substituing isla variables with already typed expressions *)
let rec exp_add_type_var_subst (vconv : int -> 'a -> ('v, 'm) Exp.Typed.t) (exp : 'a Base.exp) :
    ('v, 'm) Exp.Typed.t =
  let at = exp_add_type_var_subst vconv in
  match exp with
  | Var (v, a) -> vconv v a
  | Bits (bv, _) -> Exp.Typed.bits_smt bv
  | Bool (b, _) -> Exp.Typed.bool b
  | Enum (e, _) -> Exp.Typed.enum e
  | Unop (op, e, _) -> Exp.Typed.unop (unop op) (at e)
  | Binop (op, e, e', _) -> Exp.Typed.binop (binop op) (at e) (at e')
  | Manyop (op, el, _) -> Exp.Typed.manyop (manyop op) (List.map at el)
  | Ite (cond, e, e', _) -> Exp.Typed.ite ~cond:(at cond) (at e) (at e')

let smt_var_conv (vconv : int -> 'v) : 'a Base.smt -> ('a, 'v, 'b, 'm) Ast.smt = function
  | DeclareConst (i, t) -> DeclareConst (vconv i, ty t)
  | DefineConst (i, e) -> DefineConst (vconv i, exp_var_conv vconv e)
  | Assert e -> Assert (exp_var_conv vconv e)
  | DefineEnum _ -> failwith "unimplemented"

let smt s = smt_var_conv Fun.id s

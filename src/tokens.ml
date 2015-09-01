open Util

(* Regular expressions that describe various syntactic entities *)
let number_re = Str.regexp "[0-9]+"
let ident_re = Str.regexp "[a-zA-Z][a-zA-Z0-9]*\\|[-+*/<=]\\|:=\\|&&\\|||"
let space_re = Str.regexp "[ \t]+"
let newline_re = Str.regexp "\n"
let bracket_re = Str.regexp "[(){}]"

(* Primitive operators *)
type op = 
  | Plus
  | Minus
  | Times
  | Div
  | Lt
  | Eq
  | And
  | Or
      [@@deriving show]

type token = 
  | Num of Int64.t
  | Ident of string
  | Op of op
  | Lparen
  | Rparen
  | Lcurly
  | Rcurly
  | While
  | If
  | Then
  | Else
  | Assign
  | True
  | False
  | Input
  | Output
      [@@deriving show]

type tok_loc = (token * int) list
    [@@ deriving show]

let keywords = 
  [("while",While); ("if",If); ("then",Then); ("else",Else); (":=",Assign);
   ("true",True); ("input", Input); ("output",Output); ("false",False);
   ("+", Op Plus); ("-", Op Minus); ("*", Op Times); ("/", Op Div);
   ("<", Op Lt); ("=", Op Eq); ("&&", Op And); ("||", Op Or);]

(* Map each keyword string to its corresponding token *)
let keyword_map : token Strmap.t =
  List.fold_left (fun m (k,v) -> Strmap.add k v m) Strmap.empty keywords

let brackets =
  [("(", Lparen); (")", Rparen); ("{", Lcurly); ("}", Rcurly);]

(* Map each type of bracket to its corresponding token *)
let brackets_map : token Strmap.t =
  List.fold_left (fun m (k,v) -> Strmap.add k v m) Strmap.empty brackets

(* Read all the tokens from s, using pos to index into the string and line_n
   to track the current line number, but error reporting later on. Return them
   in a list. *)
let rec lex (s : string) (pos : int) (line_n : int) : tok_loc = 
  if pos >= String.length s then
    []
  else if Str.string_match space_re s pos then
    lex s (Str.match_end ()) line_n
  else if Str.string_match newline_re s pos then
    lex s (Str.match_end ()) (line_n + 1)
  else if Str.string_match ident_re s pos then
    let ident = Str.matched_string s in
    let tok = 
      try Strmap.find ident keyword_map
      with Not_found -> Ident ident
    in
    (tok, line_n) :: lex s (Str.match_end ()) line_n
  else if Str.string_match number_re s pos then
    let num = 
      try Int64.of_string (Str.matched_string s)
      with Failure _ -> 
        raise (BadInput ("Integer constant too big " ^ 
                         Str.matched_string s ^
                         " on line " ^
                         string_of_int line_n))
    in
    (Num num, line_n) :: lex s (Str.match_end ()) line_n
  else if Str.string_match bracket_re s pos then
    let b = Str.matched_string s in
    let tok =
      try Strmap.find b brackets_map
      with Not_found -> raise (InternalError "lex")
    in
    (tok, line_n) :: lex s (Str.match_end ()) line_n
  else
    raise (BadInput ("Unknown character '" ^ 
                     String.sub s pos 1 ^ 
                     "' on line " ^
                     string_of_int line_n))


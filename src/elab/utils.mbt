///|
fn loc_of_type(ty : @syntax.Type) -> @syntax_types.Location {
  match ty {
    Option(loc~, ..) => loc
    Name(loc~, ..) => loc
    Tuple(loc~, ..) => loc
    Arrow(loc~, ..) => loc
    Any(loc~) => loc
    Object(constr_id) => constr_id.loc
  }
}

///|
fn @syntax_types.Location::sub(
  self : @syntax_types.Location,
  width : Int,
) -> @syntax_types.Location {
  let start = self.start
  let end = { ..start, cnum: start.cnum + width }
  @syntax_types.Location::{ start, end }
}

///|
fn @syntax_types.Location::rev_sub(
  self : @syntax_types.Location,
  width : Int,
) -> @syntax_types.Location {
  let end = self.end
  let start = { ..end, cnum: end.cnum - width }
  @syntax_types.Location::{ start, end }
}

///|
fn @syntax_types.Location::start_to_spans(
  self : @syntax_types.Location,
) -> Array[SingleLineSpan] {
  let start = self.start
  [
    SingleLineSpan::{
      line: start.lnum,
      start_col: start.column(),
      end_col: start.column(),
    },
  ]
}

///|
fn @syntax_types.Location::end_to_spans(
  self : @syntax_types.Location,
) -> Array[SingleLineSpan] {
  let end = self.end
  [
    SingleLineSpan::{
      line: end.lnum,
      start_col: end.column(),
      end_col: end.column(),
    },
  ]
}

///|
fn @syntax.LongIdent::to_str(self : @syntax.LongIdent) -> String {
  match self {
    Ident(name~) => name
    Dot(pkg~, id~) => "@\{pkg}.\{id}"
  }
}

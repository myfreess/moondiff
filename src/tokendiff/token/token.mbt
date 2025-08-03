// Array[(@tokens.Token, @basic.Position, @basic.Position)]

///|
typealias @span.Text

///|
pub enum MbtToken {
  Visible(Text)
  NewLine
  Whitespace(Int)
}

///|
fn is_continuum(prev : @basic.Position, next : @basic.Position) -> Bool {
  (prev.lnum == next.lnum && prev.column() + 1 == next.column()) ||
  (prev.lnum + 1 == next.lnum && next.column() == 1)
}

///|
fn whitespace_width(prev : @basic.Position, next : @basic.Position) -> Int {
  if prev.lnum == next.lnum {
    next.column() - prev.column()
  } else {
    next.column()
  }
}

///|
pub fn MbtToken::from_triples(
  triples : Array[(@tokens.Token, @basic.Position, @basic.Position)],
  line_widths : @span.LineWidths,
) -> Array[MbtToken] {
  let mbt_tokens = Array::new(capacity=triples.length())
  let mut prev_pos = @basic.Position::{
    lnum: -1,
    fname: "dummy",
    bol: -1,
    cnum: -1,
  }
  for triple in triples {
    match triple.0 {
      SEMI(false) => continue
      NEWLINE => mbt_tokens.push(NewLine)
      _ => {
        if prev_pos.lnum != -1 && not(is_continuum(prev_pos, triple.1)) {
          let width = whitespace_width(prev_pos, triple.1)
          mbt_tokens.push(Whitespace(width))
        }
        prev_pos = triple.2
        let text = line_widths.text_of_loc(triple.1, triple.2)
        mbt_tokens.push(Visible(text))
      }
    }
  }
  return mbt_tokens
}

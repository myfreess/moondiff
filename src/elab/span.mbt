///|
pub struct SingleLineSpan {
  line : Int
  start_col : Int
  end_col : Int
}

///|
struct LineWidths(Array[Int]) derive(Show)

///|
fn LineWidths::op_get(self : Self, line : Int) -> Int {
  self.inner()[line]
}

///|
fn LineWidths::from_bytes(bytes : Bytes) -> Self {
  let positions = Array::new(capacity=bytes.length() / 20)
  positions.push(0) // dummy for line 0
  let mut width = 0
  for i = 0; i < bytes.length(); i = i + 1 {
    if bytes[i] == '\n' { // newline
      positions.push(width)
      width = 0
    } else {
      width += 1
    }
  } else {
    return positions
  }
}

///|
test "line widths" {
  let bytes = b"Hello\nWorld\n"
  let line_widths = LineWidths::from_bytes(bytes)
  inspect(line_widths, content="LineWidths([0, 5, 5])")
}

///|
fn LineWidths::loc_to_spans(
  self : Self,
  loc : @syntax_types.Location,
) -> Array[SingleLineSpan] {
  let start_line = loc.start.lnum
  let end_line = loc.end.lnum
  let spans = Array::new()
  if start_line == end_line {
    return [
      SingleLineSpan::{
        line: start_line,
        start_col: loc.start.column(),
        end_col: loc.end.column(),
      },
    ]
  }
  for line in start_line..<end_line {
    let start_col = if line == start_line { loc.start.column() } else { 0 }
    let end_col = self[line]
    spans.push(SingleLineSpan::{ line, start_col, end_col })
  } else {
    spans.push(SingleLineSpan::{
      line: end_line,
      start_col: 0,
      end_col: loc.end.column(),
    })
    return spans
  }
}

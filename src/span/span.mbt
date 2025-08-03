///|
pub(all) struct SingleLineSpan {
  line : Int
  start_col : Int
  end_col : Int
} derive(ToJson)

///|
pub struct Line(Array[Char]) derive(Show)

///|
pub impl ToJson for Line with to_json(self) {
  self.inner().to_json()
}

///|
pub struct LineWidths(Array[Line]) derive(Show)

///|
pub impl ToJson for LineWidths with to_json(self) {
  self.inner().to_json()
}

///|
pub fn LineWidths::op_get(self : Self, line : Int) -> Int {
  self.inner()[line].inner().length()
}

///|
pub fn LineWidths::from_bytes(bytes : Bytes) -> Self {
  let mut bytes = bytes[:]
  let positions = Array::new(capacity=bytes.length() / 20)
  positions.push(Line([])) // dummy for line 0
  let mut line = []
  while true {
    match bytes using regex {
      ["(?utf8:\\n|\\r|\\r\\n|\\u2028|\\u2029)", .. rest] => {
        positions.push(line)
        line = []
        bytes = rest
      }
      ["(?utf8:.)" as c, .. rest] => {
        line.push(c)
        bytes = rest
      }
      [] => {
        if !line.is_empty() {
          positions.push(Line(line))
        }
        break
      }
      _ => panic()
    }
  }
  return LineWidths(positions)
}

///|
test "line widths" {
  let bytes = b"Hello,\nWorld\n"
  let line_widths = LineWidths::from_bytes(bytes)
  inspect(
    line_widths,
    content="LineWidths([Line([]), Line(['H', 'e', 'l', 'l', 'o', ',']), Line(['W', 'o', 'r', 'l', 'd'])])",
  )
}

///|
pub enum Text {
  SingleLine(ArrayView[Char])
  MultiLine(Array[ArrayView[Char]])
} derive(Show)

///|
pub fn LineWidths::text_of_loc(
  self : Self,
  start_pos : @basic.Position,
  end_pos : @basic.Position,
) -> Text {
  if start_pos.lnum == end_pos.lnum {
    let line = self.inner()[start_pos.lnum]
    return SingleLine(line.inner()[start_pos.column() - 1:end_pos.column() - 1])
  }
  // handle multi-line case
  let multi = Array::new()
  for i in start_pos.lnum..=end_pos.lnum {
    let line = self.inner()[i]
    if i == start_pos.lnum {
      multi.push(line.inner()[start_pos.column() - 1:])
    } else if i == end_pos.lnum {
      multi.push(line.inner()[:end_pos.column() - 1])
    } else {
      multi.push(line.inner()[:])
    }
  }
  return MultiLine(multi)
}

///|
pub fn LineWidths::loc_to_spans(
  self : Self,
  loc : @basic.Location,
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

///|
pub fn LineWidths::forward_search(
  self : Self,
  symbol : Char,
  start_pos : @basic.Position,
) -> SingleLineSpan {
  let line = start_pos.lnum
  let column = start_pos.column()
  // search in the current line
  for i = column; i < self.inner()[line].inner().length(); i = i + 1 {
    if self.inner()[line].inner()[i] == symbol {
      return SingleLineSpan::{ line, start_col: i, end_col: i + 1 }
    }
  }
  let line = line + 1
  for i = 0; i < self.inner()[line].inner().length(); i = i + 1 {
    if self.inner()[line].inner()[i] == symbol {
      return SingleLineSpan::{ line, start_col: i, end_col: i + 1 }
    }
  }
  panic() // impossible
}

///|
pub fn LineWidths::backward_search(
  self : Self,
  symbol : Char,
  start_pos : @basic.Position,
) -> SingleLineSpan {
  let line = start_pos.lnum
  let column = start_pos.column()
  // search in the current line
  for i = column - 2; i >= 0; i = i - 1 {
    if self.inner()[line].inner()[i] == symbol {
      return SingleLineSpan::{ line, start_col: i, end_col: i + 1 }
    }
  }
  let line = line - 1
  for i = self.inner()[line].inner().length() - 1; i >= 0; i = i - 1 {
    if self.inner()[line].inner()[i] == symbol {
      return SingleLineSpan::{ line, start_col: i, end_col: i + 1 }
    }
  }
  panic() // impossible
}

///|
test {
  let bytes = b"foo {\n [ bar ] \n} baz\n"
  let line_widths = LineWidths::from_bytes(bytes)
  @json.inspect(line_widths, content=[
    [],
    ["f", "o", "o", " ", "{"],
    [" ", "[", " ", "b", "a", "r", " ", "]", " "],
    ["}", " ", "b", "a", "z"],
  ])
  let pos_bar_start = @basic.Position::{ lnum: 2, fname: "", bol: 5, cnum: 8 }
  let pos_bar_end = @basic.Position::{ lnum: 2, fname: "", bol: 5, cnum: 10 }
  inspect(pos_bar_start.column(), content="4")
  inspect(pos_bar_end.column(), content="6")
  @json.inspect(line_widths.forward_search('}', pos_bar_end), content={
    "line": 3,
    "start_col": 0,
    "end_col": 1,
  })
  @json.inspect(line_widths.backward_search('{', pos_bar_start), content={
    "line": 1,
    "start_col": 4,
    "end_col": 5,
  })
  @json.inspect(line_widths.backward_search('[', pos_bar_start), content={
    "line": 2,
    "start_col": 1,
    "end_col": 2,
  })
  @json.inspect(line_widths.forward_search(']', pos_bar_start), content={
    "line": 2,
    "start_col": 7,
    "end_col": 8,
  })
}

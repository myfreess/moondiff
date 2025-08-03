///|
fn lexing_then_recover(filename : String) -> Unit raise {
  let bytes = @fs.read_file_to_bytes(filename)
  let triples = @lexer.tokens_from_bytes(comment=true, bytes, name=filename).tokens
  let line_widths = @span.LineWidths::from_bytes(bytes)
  let texts = MbtToken::from_triples(triples, line_widths)
  let buf = StringBuilder::new(size_hint=texts.length() * 5)
  for text in texts {
    match text {
      Whitespace(n) =>
        for _ in 0..<n {
          buf.write_char(' ')
        }
      Visible(SingleLine(text)) => buf.write_iter(text.iter())
      Visible(MultiLine(texts)) => {
        let len = texts.length()
        for i in 0..<len {
          if i < len - 1 {
            buf.write_iter(texts[i].iter())
            buf.write_char('\n')
          } else {
            buf.write_iter(texts[i].iter())
          }
        }
      }
      NewLine => buf.write_char('\n')
    }
  }
}

///|
pub suberror ParseError {
  ParseError(Reason)
} derive(Debug)

///|
pub enum Reason {
  InvalidByte(Int, Char)
  UnexpectedEnd(Checkpoint)
  UnexpectedSequence(Array[Char], Int)
} derive(Debug)

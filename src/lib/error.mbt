///|
pub suberror ParseError {
  ParseError(Reason)
} derive(Debug)

///|
pub enum Reason {
  InvalidByte(Int32, Char)
  UnexpectedEnd(Checkpoint)
  UnexpectedSequence(Array[Char], Int32)
} derive(Debug)

///|
pub extend ParseError with @debug.Debug::{to_repr}

///|
pub extend Reason with @debug.Debug::{to_repr}

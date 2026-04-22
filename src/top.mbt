///|
pub using @lib {
  trait Decode,
  decode,
  decode_start,
  decode_continue,
  type Value,
  type ContinueValue,
  type FinishValue,
  type ParseError,
  type Reason,
}

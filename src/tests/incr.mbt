///|
fn continue_chunks(chunks : ArrayView[String], value : Value) -> Json raise {
  match (chunks, value) {
    ([], Finish({ value, .. })) => value
    ([chunk, .. rest], Continue(state)) =>
      continue_chunks(rest, decode_continue(chunk, state))
    _ => raise InspectError::InspectError("unreachable")
  }
}

///|
test "incr json" {
  let compelet_json =
    #|{"foo": {"bar": 1.2e3}, "quz": [42, true]}
  guard compelet_json.to_array().chunks(6).map(String::from_array)
    is [first_chunk, .. chunks]
  // start parsing from `first_chunk`
  let value = continue_chunks(chunks, decode_start(first_chunk))
  let expected = Json::object({
    "foo": Json::object({ "bar": Json::number(1200.0) }),
    "quz": Json::array([Json::number(42.0), Json::boolean(true)]),
  })
  assert_eq(value, expected)
}

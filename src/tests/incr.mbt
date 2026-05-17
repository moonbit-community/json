///|
fn incr_fail(message : String) -> Unit raise {
  raise InspectError::InspectError(message)
}

///|
fn continue_chunks(chunks : ArrayView[String], value : Value) -> Value raise {
  match (chunks, value) {
    ([], value) => value
    ([chunk, .. rest], Continue(state)) =>
      continue_chunks(rest, decode_continue(chunk, state))
    ([_, ..], Finish(_)) =>
      raise InspectError::InspectError("parser finished before all chunks")
  }
}

///|
fn decode_chunks(chunks : ArrayView[String]) -> Value raise {
  match chunks {
    [first_chunk, .. chunks] =>
      continue_chunks(chunks, decode_start(first_chunk))
    [] => raise InspectError::InspectError("expected at least one chunk")
  }
}

///|
fn expect_chunked_json(
  name : String,
  chunks : ArrayView[String],
  expected : Json,
) -> Unit raise {
  match decode_chunks(chunks) {
    Finish({ value, rest: [], .. }) => @debug.assert_eq(value, expected)
    Finish({ rest, .. }) =>
      incr_fail(
        "expected chunked JSON without trailing bytes: " +
        name +
        ", got " +
        String::from_array([..rest]),
      )
    Continue(_) => incr_fail("expected chunked JSON to finish: " + name)
  }
}

///|
fn expect_chunked_reject(
  name : String,
  chunks : ArrayView[String],
) -> Unit raise {
  try decode_chunks(chunks) catch {
    @lib.ParseError(_) => ()
    _ =>
      incr_fail(
        "expected chunked parser rejection, got non-parser error: " + name,
      )
  } noraise {
    Continue(_) =>
      incr_fail("expected chunked parser rejection, got continuation: " + name)
    Finish(_) =>
      incr_fail("expected chunked parser rejection, parser accepted: " + name)
  }
}

///|
test "incr json" {
  let compelet_json =
    #|{"foo": {"bar": 1.2e3}, "quz": [42, true]}
  guard compelet_json.to_array().chunks(6).map(String::from_array)
    is [first_chunk, .. chunks]
  // start parsing from `first_chunk`
  guard continue_chunks(chunks, decode_start(first_chunk))
    is Finish({ value, .. })
  let expected = Json::object({
    "foo": Json::object({ "bar": Json::number(1200.0) }),
    "quz": Json::array([Json::number(42.0), Json::boolean(true)]),
  })
  @debug.assert_eq(value, expected)
}

///|
test "incr string escapes can cross chunks" {
  expect_chunked_json(
    "quote escape crosses chunk",
    ["\"\\", "\"\""][:],
    Json::string("\""),
  )
  expect_chunked_json(
    "backslash escape crosses chunk",
    ["\"\\", "\\\""][:],
    Json::string("\\"),
  )
  expect_chunked_json(
    "slash escape crosses chunk",
    ["\"\\", "/\""][:],
    Json::string("/"),
  )
  expect_chunked_json(
    "newline escape crosses chunk",
    ["\"\\", "n\""][:],
    Json::string("\n"),
  )
}

///|
test "incr unicode escape can cross chunks" {
  expect_chunked_json(
    "unicode escape can cross chunks",
    ["\"", "\\uD8", "34\\", "uDD", "1E", "\""][:],
    Json::string("\u{1d11e}"),
  )
}

///|
test "incr numbers can cross chunks" {
  expect_chunked_json(
    "numbers can cross chunks",
    ["[", "-12", ".34", "e+", "5", "]"][:],
    Json::array([Json::number(-1234000.0)]),
  )
}

///|
test "incr invalid json rejects after continuation" {
  expect_chunked_reject(
    "missing comma between array elements",
    ["[1", " true]"][:],
  )
  expect_chunked_reject("invalid unicode escape", ["\"\\uD8", "34\\u0000\""][:])
  expect_chunked_reject("invalid exponent", ["[1", "e+]"][:])
}

///|
test "incr finish keeps trailing rest" {
  match decode_chunks(["{\"a", "\":1} trailing"][:]) {
    Finish({ value, rest, .. }) => {
      @debug.assert_eq(value, Json::object({ "a": Json::number(1.0) }))
      assert_eq(String::from_array([..rest]), " trailing")
    }
    Continue(_) =>
      incr_fail("expected chunked parser to finish with trailing rest")
  }
}

///|
test "incr nested stack resumes across chunks" {
  expect_chunked_json(
    "nested stack resumes across chunks",
    ["{\"a\":[", "{\"b\":[", "tru", "e,{", "\"c\"", ":nul", "l}]}]}"][:],
    Json::object({
      "a": Json::array([
        Json::object({
          "b": Json::array([
            Json::boolean(true),
            Json::object({ "c": Json::null() }),
          ]),
        }),
      ]),
    }),
  )
}

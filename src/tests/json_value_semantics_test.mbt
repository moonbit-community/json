///|
test "json value semantics basics" {
  let actual = @json.decode("[false,1,\"x\",null,{\"a\":true}]")
  let expected = Json::array([
    Json::boolean(false),
    Json::number(1.0),
    Json::string("x"),
    Json::null(),
    Json::object({ "a": Json::boolean(true) }),
  ])
  assert_eq(actual, expected)
}

///|
test "json value semantics duplicate object key keeps first value" {
  let actual = @json.decode("{\"a\":\"b\",\"a\":\"c\"}")
  let expected = Json::object({ "a": Json::string("b") })
  assert_eq(actual, expected)
}

///|
test "json value semantics escaped unicode is decoded" {
  let actual = @json.decode("\"\\u0000\"")
  assert_eq(actual, Json::string("\u{0}"))
}

///|
test "json value semantics allowed escapes are decoded" {
  let actual = @json.decode("[\"\\\"\\\\\\/\\b\\f\\n\\r\\t\"]")
  let expected = String::from_array(
    ['"', '\\', '/', '\u{08}', '\u{0c}', '\n', '\r', '\t'][:],
  )
  assert_eq(actual, Json::array([Json::string(expected)]))
}

///|
test "json value semantics surrogate pair is decoded" {
  let actual = @json.decode("\"\\uD834\\uDD1E\"")
  assert_eq(actual, Json::string("\u{1d11e}"))
}

///|
test "json value semantics invalid string escapes are parser errors" {
  expect_reject("manual invalid escape", "\"\\x\"")
  expect_reject("manual unescaped newline", "\"a\nb\"")
  expect_reject("manual unescaped tab", "\"\t\"")
  expect_reject("manual unescaped nul", "\"\u{0}\"")
  expect_reject("manual lone high surrogate", "\"\\uD834\"")
  expect_reject("manual lone low surrogate", "\"\\uDD1E\"")
}

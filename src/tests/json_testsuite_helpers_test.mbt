///|
fn json_testsuite_fail(message : String) -> Unit raise {
  raise InspectError::InspectError(message)
}

///|
fn expect_accept(name : String, input : String) -> Unit raise {
  try @json.decode(input) catch {
    _ => json_testsuite_fail("expected JSONTestSuite accept: " + name)
  } noraise {
    _ => ()
  }
}

///|
fn expect_reject(name : String, input : String) -> Unit raise {
  try @json.decode(input) catch {
    @lib.ParseError(_) => ()
    _ =>
      json_testsuite_fail(
        "expected JSONTestSuite parser rejection, got non-parser error: " + name,
      )
  } noraise {
    _ =>
      json_testsuite_fail(
        "expected JSONTestSuite rejection, parser accepted: " + name,
      )
  }
}

///|
fn expect_accept_or_reject(name : String, input : String) -> Unit raise {
  try @json.decode(input) catch {
    @lib.ParseError(_) => ()
    _ =>
      json_testsuite_fail(
        "expected JSONTestSuite accept or parser rejection, got non-parser error: " +
        name,
      )
  } noraise {
    _ => ()
  }
}

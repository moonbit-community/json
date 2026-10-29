///|
pub type JsonArray = Array[Json]

///|
pub type JsonObject = Map[String, Json]

///|
pub trait Decode {
  fn array_start(Self, JsonArray) -> JsonArray
  fn array_push(Self, Json, JsonArray) -> JsonArray
  fn array_finish(Self, JsonArray, JsonArray) -> (JsonArray, JsonArray)
  fn object_start(Self, JsonObject) -> JsonObject
  fn object_push(Self, String, Json, JsonObject) -> JsonObject
  fn object_finish(Self, JsonObject, JsonObject) -> (JsonObject, JsonObject)
  fn double(Self, ArrayView[Char]) -> Double raise
  fn integer(Self, ArrayView[Char]) -> Int32 raise
  fn string(Self, String) -> String
}

///|
impl Decode for Unit with fn array_start(_self, _old_acc) -> JsonArray {
  []
}

///|
impl Decode for Unit with fn array_push(_self, elem, acc) {
  [elem, ..acc]
}

///|
impl Decode for Unit with fn array_finish(_self, acc, old_acc) {
  (acc.rev(), old_acc)
}

///|
impl Decode for Unit with fn object_start(_self, _old_acc) -> JsonObject {
  Map([])
}

///|
impl Decode for Unit with fn object_push(_self, key, value, acc) {
  if !acc.contains(key) {
    acc[key] = value
  }
  acc
}

///|
impl Decode for Unit with fn object_finish(_self, acc, old_acc) {
  (acc, old_acc)
}

///|
impl Decode for Unit with fn double(_self, view) -> Double raise {
  @string.parse_double(String::from_iter(view.iter()))
}

///|
impl Decode for Unit with fn integer(_self, view) -> Int32 raise {
  @string.parse_int(String::from_iter(view.iter()))
}

///|
impl Decode for Unit with fn string(_self, s) {
  s
}

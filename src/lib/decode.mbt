///|
pub type JsonArray = Array[Json]

///|
pub type JsonObject = Map[String, Json]

///|
pub trait Decode {
  array_start(Self, JsonArray) -> JsonArray
  array_push(Self, Json, JsonArray) -> JsonArray
  array_finish(Self, JsonArray, JsonArray) -> (JsonArray, JsonArray)
  object_start(Self, JsonObject) -> JsonObject
  object_push(Self, String, Json, JsonObject) -> JsonObject
  object_finish(Self, JsonObject, JsonObject) -> (JsonObject, JsonObject)
  double(Self, ArrayView[Char]) -> Double raise
  integer(Self, ArrayView[Char]) -> Int raise
  string(Self, String) -> String
}

///|
impl Decode for Unit with array_start(_self, _old_acc) -> JsonArray {
  []
}

///|
impl Decode for Unit with array_push(_self, elem, acc) {
  [elem, ..acc]
}

///|
impl Decode for Unit with array_finish(_self, acc, old_acc) {
  (acc.rev(), old_acc)
}

///|
impl Decode for Unit with object_start(_self, _old_acc) -> JsonObject {
  Map::new()
}

///|
impl Decode for Unit with object_push(_self, key, value, acc) {
  acc[key] = value
  acc
}

///|
impl Decode for Unit with object_finish(_self, acc, old_acc) {
  (acc, old_acc)
}

///|
impl Decode for Unit with double(_self, view) -> Double raise {
  @string.parse_double(String::from_iter(view.iter()))
}

///|
impl Decode for Unit with integer(_self, view) -> Int raise {
  @string.parse_int(String::from_iter(view.iter()))
}

///|
impl Decode for Unit with string(_self, s) {
  s
}

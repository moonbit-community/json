///|
pub enum Value {
  Continue(ContinueValue)
  Finish(FinishValue)
}

///|
pub struct ContinueValue {
  rest : ArrayView[Char]
  arr_acc : JsonArray
  obj_acc : JsonObject
  stack : Array[Frame]
  decode : &Decode
  checkpoint : Checkpoint
}

///|
pub struct FinishValue {
  value : Json
  arr_acc : JsonArray
  obj_acc : JsonObject
  rest : ArrayView[Char]
} derive(Debug)

///|
enum Checkpoint {
  Value
  NumberI(Int)
  NumberD(Double)
  ArrayPush(Json)
  ObjectKey
  ObjectValue(String)
  ObjectPush((Json, String))
  FloatError(ArrayView[Char], Int)
} derive(Debug)

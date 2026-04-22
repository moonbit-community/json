///|
priv struct Context {
  original : Array[Char]
  rest : ArrayView[Char]
  skip : Int
  arr_acc : Array[Json]
  obj_acc : Map[String, Json]
  stack : Array[Frame]
  decode : &Decode
}

///|
enum Frame {
  Array(Array[Json])
  Map(Map[String, Json])
  Key(String)
} derive(Debug)

///|
pub fn decode(input : String, decode? : &Decode) -> Json raise {
  let decode : &Decode = match decode {
    Some(decode) => decode
    None => ()
  }
  let ctx = Context::{
    rest: input.to_array()[:],
    original: input.to_array(),
    skip: 0,
    arr_acc: [],
    obj_acc: Map::new(),
    stack: [],
    decode,
  }
  match value(ctx) {
    Finish({ value, rest: [], .. }) => value
    Finish({ rest, .. }) => raise invalid_byte([..rest], 0)
    Continue({ stack: [], checkpoint: Checkpoint::NumberI(n), .. }) =>
      n.to_json()
    Continue({ stack: [], checkpoint: Checkpoint::NumberD(n), .. }) =>
      n.to_json()
    Continue({ checkpoint: Checkpoint::FloatError(token, skip), .. }) =>
      raise ParseError(UnexpectedSequence(token.to_array(), skip))
    Continue({ checkpoint: cp, .. }) => raise ParseError(UnexpectedEnd(cp))
  }
}

///|
pub fn decode_start(input : String, decode? : &Decode) -> Value raise {
  let decode : &Decode = match decode {
    Some(decode) => decode
    None => ()
  }
  let ctx = Context::{
    rest: input.to_array()[:],
    original: input.to_array(),
    skip: 0,
    arr_acc: [],
    obj_acc: Map::new(),
    stack: [],
    decode,
  }
  value(ctx)
}

///|
pub fn decode_continue(cont : String, state : ContinueValue) -> Value raise {
  let input = [..state.rest, ..cont.to_array()]
  let ctx = Context::{
    rest: input[:],
    original: input,
    skip: 0,
    arr_acc: state.arr_acc,
    obj_acc: state.obj_acc,
    stack: state.stack,
    decode: state.decode,
  }
  match state.checkpoint {
    Value | NumberI(_) | NumberD(_) | FloatError(_, _) => value(ctx)
    ArrayPush(v) => array_push(ctx, v)
    ObjectKey => object_key(ctx)
    ObjectValue(key) => object_value(ctx, key)
    ObjectPush((value, key)) => object_push(ctx, value, key)
  }
}

///|
fn value(ctx : Context) -> Value raise {
  match ctx.rest {
    // skip whitespace
    ['\ ' | '\n' | '\r' | '\t', .. rest] =>
      value({ ..ctx, rest, skip: ctx.skip + 1 })
    ['0', .. rest] => number_zero({ ..ctx, rest, }, 1)
    ['1'..='9', .. rest] => number({ ..ctx, rest, }, 1)
    ['-', .. rest] => number_minus({ ..ctx, rest, })
    ['t', .. rest] => true_({ ..ctx, rest, })
    ['f', .. rest] => false_({ ..ctx, rest, })
    ['n', .. rest] => null({ ..ctx, rest, })
    ['"', .. rest] => string({ ..ctx, rest, skip: ctx.skip + 1 }, 0)
    ['[', .. rest] => array_start({ ..ctx, rest, }, 1)
    ['{', .. rest] => object_start({ ..ctx, rest, }, 1)
    _ => unexpected(ctx, 0, 0, Checkpoint::Value)
  }
}

// number {{{

///|
fn number_zero(ctx : Context, len : Int) -> Value raise {
  match ctx.rest {
    [] => {
      let value = ctx.decode.integer(['0'][:])
      unexpected(ctx, len, 0, Checkpoint::NumberI(value))
    }
    ['.', .. rest] => number_frac({ ..ctx, rest, }, len + 1)
    ['e' | 'E', .. rest] => number_exp_copy({ ..ctx, rest, }, len + 1, ['0'])
    rest => {
      let value = ctx.decode.integer(['0'][:])
      continue_(
        { ..ctx, rest, skip: ctx.skip + len },
        Json::number(value.to_double()),
      )
    }
  }
}

///|
fn number(ctx : Context, len : Int) -> Value raise {
  let { original, skip, .. } = ctx
  match ctx.rest {
    ['0'..='9', .. rest] => number({ ..ctx, rest, }, len + 1)
    ['.', .. rest] => number_frac({ ..ctx, rest, }, len + 1)
    ['e' | 'E', .. rest] => {
      let prefix = original[skip:skip + len]
      number_exp_copy({ ..ctx, rest, }, len + 1, prefix)
    }
    [] => {
      let part = original[skip:skip + len]
      let value = ctx.decode.integer(part)
      unexpected(ctx, len, 0, Checkpoint::NumberI(value))
    }
    rest => {
      let part = original[skip:skip + len]
      let value = ctx.decode.integer(part)
      continue_(
        { ..ctx, rest, skip: skip + len },
        Json::number(value.to_double()),
      )
    }
  }
}

///|
fn number_frac(ctx : Context, len : Int) -> Value raise {
  match ctx.rest {
    ['0'..='9', .. rest] => number_frac_cont({ ..ctx, rest, }, len + 1)
    _ => unexpected(ctx, len, 0, Checkpoint::Value)
  }
}

///|
fn number_frac_cont(ctx : Context, len : Int) -> Value raise {
  let { original, skip, .. } = ctx
  match ctx.rest {
    ['0'..='9', .. rest] => number_frac_cont({ ..ctx, rest, }, len + 1)
    ['e' | 'E', .. rest] => number_exp({ ..ctx, rest, }, len + 1)
    _ => {
      let token = original[skip:skip + len]
      float_decode(ctx, len, token)
    }
  }
}

///|
fn float_decode(
  ctx : Context,
  len : Int,
  token : ArrayView[Char],
) -> Value raise {
  let { skip, .. } = ctx
  match ctx.rest {
    [] =>
      try ctx.decode.double(token) catch {
        _ => unexpected(ctx, len, 0, Checkpoint::FloatError(token, skip))
      } noraise {
        value => unexpected(ctx, len, 0, Checkpoint::NumberD(value))
      }
    rest =>
      try ctx.decode.double(token) catch {
        _ => unexpected(ctx, len, 0, Checkpoint::FloatError(token, ctx.skip))
      } noraise {
        value => continue_({ ..ctx, rest, skip: skip + len }, value.to_json())
      }
  }
}

///|
fn number_exp(ctx : Context, len : Int) -> Value raise {
  match ctx.rest {
    ['0'..='9', .. rest] => number_exp_cont({ ..ctx, rest, }, len + 1)
    ['+' | '-', .. rest] => number_exp_sign({ ..ctx, rest, }, len + 1)
    _ => unexpected(ctx, len, 0, Checkpoint::Value)
  }
}

///|
fn number_exp_sign(ctx : Context, len : Int) -> Value raise {
  match ctx.rest {
    ['0'..='9', .. rest] => number_exp_cont({ ..ctx, rest, }, len + 1)
    _ => unexpected(ctx, len, 0, Checkpoint::Value)
  }
}

///|
fn number_exp_cont(ctx : Context, len : Int) -> Value raise {
  let { original, skip, .. } = ctx
  match ctx.rest {
    ['0'..='9', .. rest] => number_exp_cont({ ..ctx, rest, }, len + 1)
    _ => {
      let token = original[skip:skip + len]
      float_decode(ctx, len, token)
    }
  }
}

///|
fn number_exp_copy(
  ctx : Context,
  len : Int,
  prefix : ArrayView[Char],
) -> Value raise {
  match ctx.rest {
    ['0'..='9', .. rest] =>
      number_exp_cont_with_prefix({ ..ctx, rest, }, len, prefix, 1)
    ['+' | '-', .. rest] =>
      number_exp_sign_with_prefix({ ..ctx, rest, }, len, prefix, 1)
    _ => unexpected(ctx, len, 0, Checkpoint::Value)
  }
}

///|
fn number_exp_sign_with_prefix(
  ctx : Context,
  len : Int,
  prefix : ArrayView[Char],
  exp_len : Int,
) -> Value raise {
  match ctx.rest {
    ['0'..='9', .. rest] =>
      number_exp_cont_with_prefix({ ..ctx, rest, }, len, prefix, exp_len + 1)
    _ => unexpected(ctx, len + exp_len, 0, Checkpoint::Value)
  }
}

///|
fn number_exp_cont_with_prefix(
  ctx : Context,
  len : Int,
  prefix : ArrayView[Char],
  exp_len : Int,
) -> Value raise {
  let { original, skip, .. } = ctx
  match ctx.rest {
    ['0'..='9', .. rest] =>
      number_exp_cont_with_prefix({ ..ctx, rest, }, len, prefix, exp_len + 1)
    _ => {
      let suffix = original[skip:skip + len]
      let token = [..prefix, '.', '0', 'e', ..suffix]
      float_decode(ctx, len + exp_len, token)
    }
  }
}

///|
fn number_minus(ctx : Context) -> Value raise {
  match ctx.rest {
    ['0', .. rest] => number_zero({ ..ctx, rest, }, 2)
    ['1'..='9', .. rest] => number({ ..ctx, rest, }, 2)
    _ => unexpected(ctx, 1, 0, Checkpoint::Value)
  }
}

// }}}

// constants {{{

///|
fn true_(ctx : Context) -> Value raise {
  match ctx.rest {
    ['r', 'u', 'e', .. rest] =>
      continue_({ ..ctx, rest, skip: ctx.skip + 4 }, Json::boolean(true))
    _ => unexpected(ctx, 1, 3, Checkpoint::Value)
  }
}

///|
fn false_(ctx : Context) -> Value raise {
  match ctx.rest {
    ['a', 'l', 's', 'e', .. rest] =>
      continue_({ ..ctx, rest, skip: ctx.skip + 5 }, Json::boolean(false))
    _ => unexpected(ctx, 1, 4, Checkpoint::Value)
  }
}

///|
fn null(ctx : Context) -> Value raise {
  match ctx.rest {
    ['u', 'l', 'l', .. rest] =>
      continue_({ ..ctx, rest, skip: ctx.skip + 4 }, Json::null())
    _ => unexpected(ctx, 1, 3, Checkpoint::Value)
  }
}

// }}}

// string {{{

///|
fn string(ctx : Context, len : Int) -> Value raise {
  let { original, skip, .. } = ctx
  match ctx.rest {
    ['"', .. rest] => {
      let value = original[skip:skip + len]
      let skip = skip + len + 1
      let s = ctx.decode.string(String::from_iter(value.iter()))
      continue_({ ..ctx, rest, skip }, Json::string(s))
    }
    [_, .. rest] => string({ ..ctx, rest, }, len + 1)
    _ => unexpected({ ..ctx, skip: skip - 1 }, len + 1, 0, Checkpoint::Value)
  }
}

// }}}

// array {{{

///|
fn array_start(ctx : Context, len : Int) -> Value raise {
  let { decode, skip, arr_acc, .. } = ctx
  match ctx.rest {
    ['\ ' | '\n' | '\r' | '\t', .. rest] =>
      array_start({ ..ctx, rest, }, len + 1)
    [']', .. rest] => {
      let (value, new_acc) = ctx.decode.array_finish(
        ctx.decode.array_start(arr_acc),
        arr_acc,
      )
      continue_(
        { ..ctx, rest, skip: skip + len + 1, arr_acc: new_acc },
        Json::array(value),
      )
    }
    [] => unexpected(ctx, len, 0, Checkpoint::Value)
    rest => {
      let new_acc = decode.array_start(arr_acc)
      ctx.stack.push(Frame::Array(arr_acc))
      value({ ..ctx, rest, skip: skip + len, arr_acc: new_acc })
    }
  }
}

///|
fn array_push(ctx : Context, value0 : Json) -> Value raise {
  let { skip, .. } = ctx
  match ctx.rest {
    ['\ ' | '\n' | '\r' | '\t', .. rest] =>
      array_push({ ..ctx, rest, skip: skip + 1 }, value0)
    [']', .. rest] => {
      let acc = ctx.decode.array_push(value0, ctx.arr_acc)
      guard ctx.stack.pop() is Some(Frame::Array(old_acc))
      let (array_value, new_acc) = ctx.decode.array_finish(acc, old_acc)
      continue_(
        { ..ctx, rest, skip: skip + 1, arr_acc: new_acc },
        Json::array(array_value),
      )
    }
    [',', .. rest] => {
      let arr_acc = ctx.decode.array_push(value0, ctx.arr_acc)
      value({ ..ctx, rest, skip: skip + 1, arr_acc })
    }
    _ => unexpected(ctx, 0, 0, Checkpoint::ArrayPush(value0))
  }
}

// }}}

// object {{{

///|
fn object_start(ctx : Context, len : Int) -> Value raise {
  let { obj_acc, skip, .. } = ctx
  match ctx.rest {
    ['\ ' | '\n' | '\r' | '\t', .. rest] =>
      object_start({ ..ctx, rest, }, len + 1)
    ['}', .. rest] => {
      let (value, new_acc) = ctx.decode.object_finish(
        ctx.decode.object_start(obj_acc),
        obj_acc,
      )
      continue_(
        { ..ctx, rest, skip: skip + len + 1, obj_acc: new_acc },
        Json::object(value),
      )
    }
    ['"', .. rest] => {
      ctx.stack.push(Frame::Map(obj_acc))
      string(
        {
          ..ctx,
          rest,
          skip: skip + len + 1,
          obj_acc: ctx.decode.object_start(obj_acc),
        },
        0,
      )
    }
    _ => unexpected(ctx, len, 0, Checkpoint::Value)
  }
}

///|
fn object_value(ctx : Context, key : String) -> Value raise {
  let { skip, .. } = ctx
  match ctx.rest {
    ['\ ' | '\n' | '\r' | '\t', .. rest] =>
      object_value({ ..ctx, rest, skip: skip + 1 }, key)
    [':', .. rest] => {
      ctx.stack.push(Frame::Key(key))
      value({ ..ctx, rest, skip: skip + 1 })
    }
    _ => unexpected(ctx, 0, 0, Checkpoint::ObjectValue(key))
  }
}

///|
fn object_push(ctx : Context, value0 : Json, key : String) -> Value raise {
  let { skip, .. } = ctx
  match ctx.rest {
    ['\ ' | '\n' | '\r' | '\t', .. rest] =>
      object_push({ ..ctx, rest, skip: skip + 1 }, value0, key)
    ['}', .. rest] => {
      let acc = ctx.decode.object_push(key, value0, ctx.obj_acc)
      guard ctx.stack.pop() is Some(Frame::Map(old_acc))
      let (object_value, new_acc) = ctx.decode.object_finish(acc, old_acc)
      continue_(
        { ..ctx, rest, skip: skip + 1, obj_acc: new_acc },
        Json::object(object_value),
      )
    }
    [',', .. rest] => {
      let obj_acc = ctx.decode.object_push(key, value0, ctx.obj_acc)
      object_key({ ..ctx, rest, skip: skip + 1, obj_acc })
    }
    _ => unexpected(ctx, 0, 0, Checkpoint::ObjectPush((value0, key)))
  }
}

///|
fn object_key(ctx : Context) -> Value raise {
  let { skip, .. } = ctx
  match ctx.rest {
    ['\ ' | '\n' | '\r' | '\t', .. rest] =>
      object_key({ ..ctx, rest, skip: skip + 1 })
    ['"', .. rest] => string({ ..ctx, rest, skip: skip + 1 }, 0)
    _ => unexpected(ctx, 0, 0, Checkpoint::ObjectKey)
  }
}

// }}}

///|
fn continue_(ctx : Context, value : Json) -> Value raise {
  match ctx.stack.last() {
    None => terminate(ctx, value)
    Some(Frame::Array(_)) => array_push(ctx, value)
    Some(Frame::Map(_)) => {
      guard value is Json::String(key)
      object_value(ctx, key)
    }
    Some(Frame::Key(key)) => {
      ctx.stack.pop() |> ignore
      object_push({ ..ctx }, value, key)
    }
  }
}

///|
fn terminate(ctx : Context, value : Json) -> Value raise {
  let { rest, original, skip, arr_acc, obj_acc, .. } = ctx
  match rest {
    // skip whitespace
    ['\ ' | '\n' | '\r' | '\t', .. rest] => terminate({ ..ctx, rest, }, value)
    [] => Value::Finish({ value, arr_acc, obj_acc, rest: [][:] })
    _ => {
      let rest = original[skip:]
      Value::Finish({ value, arr_acc, obj_acc, rest })
    }
  }
}

///|
fn unexpected(
  ctx : Context,
  pos : Int,
  len : Int,
  func_data : Checkpoint,
) -> Value raise {
  let { original, arr_acc, obj_acc, skip, stack, decode, .. } = ctx
  let required_size = skip + pos + len
  let original_size = original.length()
  if original_size <= required_size {
    let rest = original[skip:]
    Value::Continue(ContinueValue::{
      rest,
      arr_acc,
      obj_acc,
      stack,
      decode,
      checkpoint: func_data,
    })
  } else {
    raise invalid_byte(ctx.original, ctx.skip + pos)
  }
}

///|
fn invalid_byte(arr : Array[Char], skip : Int) -> ParseError {
  let byte = arr[skip]
  ParseError(InvalidByte(skip, byte))
}

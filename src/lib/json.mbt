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
      raise ParseError(UnexpectedSequence(token.to_owned(), skip))
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
  let { original, skip, .. } = ctx
  match ctx.rest {
    [] => {
      let token = original[skip:skip + len]
      let value = integer_decode(ctx, token)
      unexpected(ctx, len, 0, Checkpoint::NumberI(value))
    }
    ['.', .. rest] => number_frac({ ..ctx, rest, }, len + 1)
    ['e' | 'E', .. rest] => number_exp({ ..ctx, rest, }, len + 1)
    rest => {
      let token = original[skip:skip + len]
      let value = integer_decode(ctx, token)
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
    ['e' | 'E', .. rest] => number_exp({ ..ctx, rest, }, len + 1)
    [] => {
      let part = original[skip:skip + len]
      let value = integer_decode(ctx, part)
      unexpected(ctx, len, 0, Checkpoint::NumberI(value))
    }
    rest => {
      let part = original[skip:skip + len]
      let value = integer_decode(ctx, part)
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
fn number_minus(ctx : Context) -> Value raise {
  match ctx.rest {
    ['0', .. rest] => number_zero({ ..ctx, rest, }, 2)
    ['1'..='9', .. rest] => number({ ..ctx, rest, }, 2)
    _ => unexpected(ctx, 1, 0, Checkpoint::Value)
  }
}

///|
fn integer_decode(ctx : Context, token : ArrayView[Char]) -> Int raise {
  try ctx.decode.integer(token) catch {
    _ => raise ParseError(UnexpectedSequence(token.to_owned(), ctx.skip))
  } noraise {
    value => value
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
  let builder = StringBuilder::new(size_hint=len)
  string_scan(ctx, len, builder)
}

///|
fn string_scan(
  ctx : Context,
  len : Int,
  builder : StringBuilder,
) -> Value raise {
  let { skip, .. } = ctx
  match ctx.rest {
    ['"', .. rest] => {
      let skip = skip + len + 1
      let s = ctx.decode.string(builder.to_string())
      continue_({ ..ctx, rest, skip }, Json::string(s))
    }
    ['\\', .. rest] => string_escape({ ..ctx, rest, }, len, builder)
    [c, .. rest] =>
      if c.to_int() < 0x20 {
        raise invalid_byte(ctx.original, skip + len)
      } else {
        builder.write_char(c)
        string_scan({ ..ctx, rest, }, len + 1, builder)
      }
    _ => unexpected({ ..ctx, skip: skip - 1 }, len + 1, 0, Checkpoint::Value)
  }
}

///|
fn string_escape(
  ctx : Context,
  len : Int,
  builder : StringBuilder,
) -> Value raise {
  match ctx.rest {
    ['"', .. rest] => {
      builder.write_char('"')
      string_scan({ ..ctx, rest, }, len + 2, builder)
    }
    ['\\', .. rest] => {
      builder.write_char('\\')
      string_scan({ ..ctx, rest, }, len + 2, builder)
    }
    ['/', .. rest] => {
      builder.write_char('/')
      string_scan({ ..ctx, rest, }, len + 2, builder)
    }
    ['b', .. rest] => {
      builder.write_char('\u{08}')
      string_scan({ ..ctx, rest, }, len + 2, builder)
    }
    ['f', .. rest] => {
      builder.write_char('\u{0c}')
      string_scan({ ..ctx, rest, }, len + 2, builder)
    }
    ['n', .. rest] => {
      builder.write_char('\n')
      string_scan({ ..ctx, rest, }, len + 2, builder)
    }
    ['r', .. rest] => {
      builder.write_char('\r')
      string_scan({ ..ctx, rest, }, len + 2, builder)
    }
    ['t', .. rest] => {
      builder.write_char('\t')
      string_scan({ ..ctx, rest, }, len + 2, builder)
    }
    ['u', a, b, c, d, .. rest] => {
      let code_unit = unicode_escape_value(ctx, len, a, b, c, d)
      string_unicode(ctx, len, code_unit, rest, builder)
    }
    ['u', ..] =>
      unexpected({ ..ctx, skip: ctx.skip - 1 }, len + 6, 0, Checkpoint::Value)
    [_, ..] => raise invalid_byte(ctx.original, ctx.skip + len + 1)
    [] =>
      unexpected({ ..ctx, skip: ctx.skip - 1 }, len + 2, 0, Checkpoint::Value)
  }
}

///|
fn string_unicode(
  ctx : Context,
  len : Int,
  code_unit : Int,
  rest : ArrayView[Char],
  builder : StringBuilder,
) -> Value raise {
  if code_unit.is_leading_surrogate() {
    match rest {
      ['\\', 'u', a, b, c, d, .. rest] => {
        let low = unicode_escape_value(ctx, len + 6, a, b, c, d)
        if low.is_trailing_surrogate() {
          let codepoint = 0x10000 +
            (code_unit - 0xD800) * 0x400 +
            (low - 0xDC00)
          write_codepoint(ctx, ctx.skip + len, codepoint, builder)
          string_scan({ ..ctx, rest, }, len + 12, builder)
        } else {
          raise invalid_byte(ctx.original, ctx.skip + len + 8)
        }
      }
      ['\\', 'u', ..] =>
        unexpected(
          { ..ctx, skip: ctx.skip - 1 },
          len + 12,
          0,
          Checkpoint::Value,
        )
      [] | ['\\'] =>
        unexpected(
          { ..ctx, skip: ctx.skip - 1 },
          len + 12,
          0,
          Checkpoint::Value,
        )
      _ => raise invalid_byte(ctx.original, ctx.skip + len + 6)
    }
  } else if code_unit.is_trailing_surrogate() {
    raise invalid_byte(ctx.original, ctx.skip + len + 2)
  } else {
    write_codepoint(ctx, ctx.skip + len + 2, code_unit, builder)
    string_scan({ ..ctx, rest, }, len + 6, builder)
  }
}

///|
fn unicode_escape_value(
  ctx : Context,
  len : Int,
  a : Char,
  b : Char,
  c : Char,
  d : Char,
) -> Int raise {
  let a = hex_value(ctx, ctx.skip + len + 2, a)
  let b = hex_value(ctx, ctx.skip + len + 3, b)
  let c = hex_value(ctx, ctx.skip + len + 4, c)
  let d = hex_value(ctx, ctx.skip + len + 5, d)
  a * 0x1000 + b * 0x100 + c * 0x10 + d
}

///|
fn hex_value(ctx : Context, index : Int, c : Char) -> Int raise {
  match c {
    '0'..='9' => c.to_int() - '0'.to_int()
    'a'..='f' => c.to_int() - 'a'.to_int() + 10
    'A'..='F' => c.to_int() - 'A'.to_int() + 10
    _ => raise invalid_byte(ctx.original, index)
  }
}

///|
fn write_codepoint(
  ctx : Context,
  index : Int,
  codepoint : Int,
  builder : StringBuilder,
) -> Unit raise {
  match codepoint.to_char() {
    Some(c) => builder.write_char(c)
    None => raise invalid_byte(ctx.original, index)
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

// credit for:
// https://github.com/nst/JSONTestSuite/tree/master/test_parsing
// MIT license

///|
test "batch i_number_double_huge_neg_exp" {
  let complete_json =
    #|[123.456e-789]
  let actual = decode(complete_json)
  inspect(actual, content="Array([Number(0)])")
}

///| FIXME: value out of range
test "panic batch i_number_huge_exp" {
  let complete_json =
    "[0.4e" +
    "006699999999999999999999999999999999999999999999999999999999" +
    "999999999999999999999999999999999999999999999999999999999999" +
    "69999999006]"
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///| FIXME: value out of range
test "panic batch i_number_neg_int_huge_exp" {
  let complete_json =
    #|[-1e+9999]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///| FIXME: value out of range
test "panic batch i_number_pos_double_huge_exp" {
  let complete_json =
    #|[1.5e+9999]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///| FIXME: value out of range
test "panic batch i_number_real_neg_overflow" {
  let complete_json =
    #|[-123123e100000]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///| FIXME: value out of range
test "panic batch i_number_real_pos_overflow" {
  let complete_json =
    #|[123123e100000]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///| FIXME: value out of range
test "panic batch i_number_real_underflow" {
  let complete_json =
    #|[123e-10000000]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///| FIXME: value out of range
test "panic batch i_number_too_big_neg_int" {
  let complete_json =
    #|[-123123123123123123123123123123]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///| FIXME: value out of range
test "panic batch i_number_too_big_pos_int" {
  let complete_json =
    #|[100000000000000000000]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///| FIXME: value out of range
test "panic batch i_number_very_big_negative_int" {
  let complete_json =
    #|[-237462374673276894279832749832423479823246327846]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch i_object_key_lone_2nd_surrogate" {
  let complete_json =
    #|{"\uDFAA":0}
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Object({"\\uDFAA": Number(0)})
    ),
  )
}

///|
test "batch i_string_1st_surrogate_but_2nd_missing" {
  let complete_json =
    #|["\uDADA"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uDADA")])
    ),
  )
}

///|
test "batch i_string_1st_valid_surrogate_2nd_invalid" {
  let complete_json =
    #|["\uD888\u1234"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uD888\\u1234")])
    ),
  )
}

///|
test "batch i_string_incomplete_surrogate_and_escape_valid" {
  let complete_json =
    #|["\uD800\n"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uD800\\n")])
    ),
  )
}

///|
test "batch i_string_incomplete_surrogate_pair" {
  let complete_json =
    #|["\uDd1ea"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uDd1ea")])
    ),
  )
}

///|
test "batch i_string_incomplete_surrogates_escape_valid" {
  let complete_json =
    #|["\uD800\uD800\n"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uD800\\uD800\\n")])
    ),
  )
}

///|
test "batch i_string_invalid_lonely_surrogate" {
  let complete_json =
    #|["\ud800"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\ud800")])
    ),
  )
}

///|
test "batch i_string_invalid_surrogate" {
  let complete_json =
    #|["\ud800abc"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\ud800abc")])
    ),
  )
}

///|
test "batch i_string_invalid_utf-8" {
  let complete_json =
    #|["ÿ"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("ÿ")])
    ),
  )
}

///|
test "batch i_string_inverted_surrogates_U+1D11E" {
  let complete_json =
    #|["\uDd1e\uD834"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uDd1e\\uD834")])
    ),
  )
}

///|
test "batch i_string_iso_latin_1" {
  let complete_json =
    #|["é"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("é")])
    ),
  )
}

///|
test "batch i_string_lone_second_surrogate" {
  let complete_json =
    #|["\uDFAA"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uDFAA")])
    ),
  )
}

///|
test "batch i_string_lone_utf8_continuation_byte" {
  let complete_json =
    #|[""]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("")])
    ),
  )
}

///|
test "batch i_string_not_in_unicode_range" {
  let complete_json =
    #|["ô¿¿¿"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("ô¿¿¿")])
    ),
  )
}

///|
test "batch i_string_overlong_sequence_2_bytes" {
  let complete_json =
    #|["À¯"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("À¯")])
    ),
  )
}

///|
test "batch i_string_overlong_sequence_6_bytes" {
  let complete_json =
    #|["ü¿¿¿¿"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("ü¿¿¿¿")])
    ),
  )
}

///|
test "batch i_string_overlong_sequence_6_bytes_null" {
  let complete_json =
    #|["ü"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("ü")])
    ),
  )
}

///|
test "batch i_string_truncated-utf-8" {
  let complete_json =
    #|["àÿ"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("àÿ")])
    ),
  )
}

///|
test "batch i_string_utf16BE_no_BOM" {
  let complete_json =
    #|["é"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("é")])
    ),
  )
}

///|
test "batch i_string_utf16LE_no_BOM" {
  let complete_json =
    #|["é"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("é")])
    ),
  )
}

///|
test "batch i_string_UTF-16LE_with_BOM" {
  let complete_json =
    #|ÿþ["é"]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch i_string_UTF-8_invalid_sequence" {
  let complete_json =
    #|["æ¥Ñú"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("æ¥Ñú")])
    ),
  )
}

///|
test "batch i_string_UTF8_surrogate_U+D800" {
  let complete_json =
    #|["í "]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("í ")])
    ),
  )
}

///|
test "batch i_structure_500_nested_arrays" {
  let complete_json = "[".repeat(500) + "]".repeat(500)
  let actual = decode(complete_json)
  let expected = "Array([".repeat(500) + "]" + "])".repeat(500)
  inspect(actual, content=expected)
}

///|
test "batch i_structure_UTF-8_BOM_empty_object" {
  let complete_json =
    #|ï»¿{}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_1_true_without_comma" {
  let complete_json =
    #|[1 true]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_a_invalid_utf8" {
  let complete_json =
    #|[aå]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_colon_instead_of_comma" {
  let complete_json =
    #|["": 1]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_comma_after_close" {
  let complete_json =
    #|[""],
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_comma_and_number" {
  let complete_json =
    #|[,1]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_double_comma" {
  let complete_json =
    #|[1,,2]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_double_extra_comma" {
  let complete_json =
    #|["x",,]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_extra_close" {
  let complete_json =
    #|["x"]]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_extra_comma" {
  let complete_json =
    #|["",]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_incomplete_invalid_value" {
  let complete_json =
    #|[x
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_incomplete" {
  let complete_json =
    #|["x"
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_inner_array_no_comma" {
  let complete_json =
    #|[3[4]]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_invalid_utf8" {
  let complete_json =
    #|[ÿ]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_items_separated_by_semicolon" {
  let complete_json =
    #|[1:2]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_just_comma" {
  let complete_json =
    #|[,]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_just_minus" {
  let complete_json =
    #|[-]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_missing_value" {
  let complete_json =
    #|[   , ""]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_newlines_unclosed" {
  let complete_json =
    #|["a",\n4\n,1,
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_number_and_comma" {
  let complete_json =
    #|[1,]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_number_and_several_commas" {
  let complete_json =
    #|[1,,]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_spaces_vertical_tab_formfeed" {
  let complete_json =
    #|["a"\f]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_star_inside" {
  let complete_json =
    #|[*]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_unclosed" {
  let complete_json =
    #|[""
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_unclosed_trailing_comma" {
  let complete_json =
    #|[1,
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_unclosed_with_new_lines" {
  let complete_json =
    #|[1,\n1\n,1
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_array_unclosed_with_object_inside" {
  let complete_json =
    #|[{}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_incomplete_false" {
  let complete_json =
    #|[fals]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_incomplete_null" {
  let complete_json =
    #|[nul]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_incomplete_true" {
  let complete_json =
    #|[tru]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_multidigit_number_then_00" {
  let complete_json =
    #|123
  let actual = decode(complete_json)
  inspect(actual, content="Number(123)")
}

///|
test "batch n_number_0.1.2" {
  let complete_json =
    #|[0.1.2]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_-01" {
  let complete_json =
    #|[-01]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_0.3e+" {
  let complete_json =
    #|[0.3e+]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_0.3e" {
  let complete_json =
    #|[0.3e]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_0_capital_E+" {
  let complete_json =
    #|[0E+]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_0_capital_E" {
  let complete_json =
    #|[0E]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_0.e1" {
  let complete_json =
    #|[0.e1]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_0e+" {
  let complete_json =
    #|[0e+]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_0e" {
  let complete_json =
    #|[0e]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_1_000" {
  let complete_json =
    #|[1 000.0]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_1.0e+" {
  let complete_json =
    #|[1.0e+]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_1.0e-" {
  let complete_json =
    #|[1.0e-]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_1.0e" {
  let complete_json =
    #|[1.0e]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_-1.0." {
  let complete_json =
    #|[-1.0.]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_1eE2" {
  let complete_json =
    #|[1eE2]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_+1" {
  let complete_json =
    #|[+1]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_.-1" {
  let complete_json =
    #|[.-1]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_2.e+3" {
  let complete_json =
    #|[2.e+3]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_2.e-3" {
  let complete_json =
    #|[2.e-3]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_2.e3" {
  let complete_json =
    #|[2.e3]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_.2e-3" {
  let complete_json =
    #|[.2e-3]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_-2." {
  let complete_json =
    #|[-2.]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_9.e+" {
  let complete_json =
    #|[9.e+]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_expression" {
  let complete_json =
    #|[1+2]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_hex_1_digit" {
  let complete_json =
    #|[0x1]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_hex_2_digits" {
  let complete_json =
    #|[0x42]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_infinity" {
  let complete_json =
    #|[Infinity]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_+Inf" {
  let complete_json =
    #|[+Inf]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_Inf" {
  let complete_json =
    #|[Inf]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_invalid+-" {
  let complete_json =
    #|[0e+-1]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_invalid-negative-real" {
  let complete_json =
    #|[-123.123foo]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_invalid-utf-8-in-bigger-int" {
  let complete_json =
    #|[123å]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_invalid-utf-8-in-exponent" {
  let complete_json =
    #|[1e1å]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_invalid-utf-8-in-int" {
  let complete_json =
    #|[0å]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_++" {
  let complete_json =
    #|[++1234]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_minus_infinity" {
  let complete_json =
    #|[-Infinity]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_minus_sign_with_trailing_garbage" {
  let complete_json =
    #|[-foo]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_minus_space_1" {
  let complete_json =
    #|[- 1]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_-NaN" {
  let complete_json =
    #|[-NaN]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_NaN" {
  let complete_json =
    #|[NaN]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_neg_int_starting_with_zero" {
  let complete_json =
    #|[-012]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_neg_real_without_int_part" {
  let complete_json =
    #|[-.123]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_neg_with_garbage_at_end" {
  let complete_json =
    #|[-1x]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_real_garbage_after_e" {
  let complete_json =
    #|[1ea]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_real_with_invalid_utf8_after_e" {
  let complete_json =
    #|[1eå]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_real_without_fractional_part" {
  let complete_json =
    #|[1.]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_starting_with_dot" {
  let complete_json =
    #|[.123]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_U+FF11_fullwidth_digit_one" {
  let complete_json =
    #|[ï¼]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_with_alpha_char" {
  let complete_json =
    #|[1.8011670033376514H-308]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_with_alpha" {
  let complete_json =
    #|[1.2a-3]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_number_with_leading_zero" {
  let complete_json =
    #|[012]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_bad_value" {
  let complete_json =
    #|["x", truth]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_bracket_key" {
  let complete_json =
    #|{[: "x"}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_comma_instead_of_colon" {
  let complete_json =
    #|{"x", null}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_double_colon" {
  let complete_json =
    #|{"x"::"b"}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_emoji" {
  let complete_json =
    #|{ð¨ð­}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_garbage_at_end" {
  let complete_json =
    #|{"a":"a" 123}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_key_with_single_quotes" {
  let complete_json =
    #|{key: 'value'}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_lone_continuation_byte_in_key_and_trailing_comma" {
  let complete_json =
    #|{"¹":"0",}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_missing_colon" {
  let complete_json =
    #|{"a" b}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_missing_key" {
  let complete_json =
    #|{:"b"}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_missing_semicolon" {
  let complete_json =
    #|{"a" "b"}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_missing_value" {
  let complete_json =
    #|{"a":
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_no-colon" {
  let complete_json =
    #|{"a"
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_non_string_key_but_huge_number_instead" {
  let complete_json =
    #|{9999E9999:1}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_non_string_key" {
  let complete_json =
    #|{1:1}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_repeated_null_null" {
  let complete_json =
    #|{null:null,null:null}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_several_trailing_commas" {
  let complete_json =
    #|{"id":0,,,,,}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_single_quote" {
  let complete_json =
    #|{'a':0}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_trailing_comma" {
  let complete_json =
    #|{"id":0,}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_trailing_comment" {
  let complete_json =
    #|{"a":"b"}/**/
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_trailing_comment_open" {
  let complete_json =
    #|{"a":"b"}/**//
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_trailing_comment_slash_open_incomplete" {
  let complete_json =
    #|{"a":"b"}/
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_trailing_comment_slash_open" {
  let complete_json =
    #|{"a":"b"}//
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_two_commas_in_a_row" {
  let complete_json =
    #|{"a":"b",,"c":"d"}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_unquoted_key" {
  let complete_json =
    #|{a: "b"}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_unterminated-value" {
  let complete_json =
    #|{"a":"a
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_with_single_string" {
  let complete_json =
    #|{ "foo" : "bar", "a" }
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_object_with_trailing_garbage" {
  let complete_json =
    #|{"a":"b"}#
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_single_space" {
  let complete_json =
    #| 
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_string_1_surrogate_then_escape" {
  let complete_json =
    #|["\uD800\"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uD800\\")])
    ),
  )
}

///|
test "batch n_string_1_surrogate_then_escape_u1" {
  let complete_json =
    #|["\uD800\u1"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uD800\\u1")])
    ),
  )
}

///|
test "batch n_string_1_surrogate_then_escape_u1x" {
  let complete_json =
    #|["\uD800\u1x"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uD800\\u1x")])
    ),
  )
}

///|
test "batch n_string_1_surrogate_then_escape_u" {
  let complete_json =
    #|["\uD800\u"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uD800\\u")])
    ),
  )
}

///|
test "batch n_string_accentuated_char_no_quotes" {
  let complete_json =
    #|[Ã©]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_string_backslash_00" {
  let complete_json =
    #|["\"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\")])
    ),
  )
}

///|
test "batch n_string_escaped_backslash_bad" {
  let complete_json =
    #|["\\\"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\\\\\")])
    ),
  )
}

///|
test "batch n_string_escaped_ctrl_char_tab" {
  let complete_json =
    #|["\	"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\\t")])
    ),
  )
}

///|
test "batch n_string_escaped_emoji" {
  let complete_json =
    #|["\ð"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\ð")])
    ),
  )
}

///|
test "batch n_string_escape_x" {
  let complete_json =
    #|["\x00"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\x00")])
    ),
  )
}

///|
test "batch n_string_incomplete_escaped_character" {
  let complete_json =
    #|["\u00A"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\u00A")])
    ),
  )
}

///|
test "batch n_string_incomplete_escape" {
  let complete_json =
    #|["\"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\")])
    ),
  )
}

///|
test "batch n_string_incomplete_surrogate_escape_invalid" {
  let complete_json =
    #|["\uD800\uD800\x"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uD800\\uD800\\x")])
    ),
  )
}

///|
test "batch n_string_incomplete_surrogate" {
  let complete_json =
    #|["\uD834\uDd"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uD834\\uDd")])
    ),
  )
}

///|
test "batch n_string_invalid_backslash_esc" {
  let complete_json =
    #|["\a"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\a")])
    ),
  )
}

///|
test "batch n_string_invalid_unicode_escape" {
  let complete_json =
    #|["\uqqqq"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uqqqq")])
    ),
  )
}

///|
test "batch n_string_invalid_utf8_after_escape" {
  let complete_json =
    #|["\å"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\å")])
    ),
  )
}

///|
test "batch n_string_invalid-utf-8-in-escape" {
  let complete_json =
    #|["\uå"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uå")])
    ),
  )
}

///|
test "batch n_string_leading_uescaped_thinspace" {
  let complete_json =
    #|[\u0020"asd"]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_string_no_quotes_with_bad_escape" {
  let complete_json =
    #|[\n]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_string_single_doublequote" {
  let complete_json =
    #|"
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_string_single_quote" {
  let complete_json =
    #|['single quote']
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_string_single_string_no_double_quotes" {
  let complete_json =
    #|abc
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_string_start_escape_unclosed" {
  let complete_json =
    #|["\
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_string_unescaped_ctrl_char" {
  let complete_json =
    #|["aa"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("aa")])
    ),
  )
}

///|
test "batch n_string_unescaped_newline" {
  let complete_json =
    #|["new\nline"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("new\\nline")])
    ),
  )
}

///|
test "batch n_string_unescaped_tab" {
  let complete_json =
    #|["	"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\t")])
    ),
  )
}

///|
test "batch n_string_unicode_CapitalU" {
  let complete_json =
    #|"\UA66D"
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|String("\\UA66D")
    ),
  )
}

///|
test "batch n_string_with_trailing_garbage" {
  let complete_json =
    #|""x
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_100000_opening_arrays" {
  let complete_json = "[".repeat(100000)
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_angle_bracket_." {
  let complete_json =
    #|<.>
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_angle_bracket_null" {
  let complete_json =
    #|[<null>]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_array_trailing_garbage" {
  let complete_json =
    #|[1]x
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_array_with_extra_array_close" {
  let complete_json =
    #|[1]]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_array_with_unclosed_string" {
  let complete_json =
    #|["asd]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_ascii-unicode-identifier" {
  let complete_json =
    #|aÃ¥
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_capitalized_True" {
  let complete_json =
    #|[True]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_close_unopened_array" {
  let complete_json =
    #|1]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_comma_instead_of_closing_brace" {
  let complete_json =
    #|{"x": true,
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_double_array" {
  let complete_json =
    #|[][]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_end_array" {
  let complete_json =
    #|]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_incomplete_UTF8_BOM" {
  let complete_json =
    #|ï»{}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_lone-invalid-utf-8" {
  let complete_json =
    #|å
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_lone-open-bracket" {
  let complete_json =
    #|[
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_no_data" {
  let complete_json =
    #|
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_null-byte-outside-string" {
  let complete_json =
    #|[]
  let actual = decode(complete_json)
  inspect(actual, content="Array([])")
}

///|
test "batch n_structure_number_with_trailing_garbage" {
  let complete_json =
    #|2@
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_object_followed_by_closing_object" {
  let complete_json =
    #|{}}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_object_unclosed_no_value" {
  let complete_json =
    #|{"":
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_object_with_comment" {
  let complete_json =
    #|{"a":/*comment*/"b"}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_object_with_trailing_garbage" {
  let complete_json =
    #|{"a": true} "x"
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_open_array_apostrophe" {
  let complete_json =
    #|['
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_open_array_comma" {
  let complete_json =
    #|[,
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_open_array_object" {
  let complete_json =
    "[" + "{\"\":[".repeat(50000) + "{\"\":"
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_open_array_open_object" {
  let complete_json =
    #|[{
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_open_array_open_string" {
  let complete_json =
    #|["a
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_open_array_string" {
  let complete_json =
    #|["a"
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_open_object_close_array" {
  let complete_json =
    #|{]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_open_object_comma" {
  let complete_json =
    #|{,
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_open_object" {
  let complete_json =
    #|{
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_open_object_open_array" {
  let complete_json =
    #|{[
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_open_object_open_string" {
  let complete_json =
    #|{"a
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_open_object_string_with_apostrophes" {
  let complete_json =
    #|{'a'
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_open_open" {
  let complete_json =
    #|["\{["\{["\{["\{
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_single_eacute" {
  let complete_json =
    #|é
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_single_star" {
  let complete_json =
    #|*
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_trailing_#" {
  let complete_json =
    #|{"a":"b"}#{}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_U+2060_word_joined" {
  let complete_json =
    #|[â ]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_uescaped_LF_before_string" {
  let complete_json =
    #|[\u000A""]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_unclosed_array" {
  let complete_json =
    #|[1
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_unclosed_array_partial_null" {
  let complete_json =
    #|[ false, nul
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_unclosed_array_unfinished_false" {
  let complete_json =
    #|[ true, fals
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_unclosed_array_unfinished_true" {
  let complete_json =
    #|[ false, tru
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_unclosed_object" {
  let complete_json =
    #|{"asd":"asd"
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_unicode-identifier" {
  let complete_json =
    #|Ã¥
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_UTF8_BOM_no_data" {
  let complete_json =
    #|ï»¿
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_whitespace_formfeed" {
  let complete_json =
    #|[]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch n_structure_whitespace_U+2060_word_joiner" {
  let complete_json =
    #|[â ]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_array_arraysWithSpaces" {
  let complete_json =
    #|[[]   ]
  let actual = decode(complete_json)
  inspect(actual, content="Array([Array([])])")
}

///|
test "batch y_array_empty" {
  let complete_json =
    #|[]
  let actual = decode(complete_json)
  inspect(actual, content="Array([])")
}

///|
test "batch y_array_empty-string" {
  let complete_json =
    #|[""]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("")])
    ),
  )
}

///|
test "batch y_array_ending_with_newline" {
  let complete_json =
    #|["a"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("a")])
    ),
  )
}

///|
test "batch y_array_false" {
  let complete_json =
    #|[false]
  let actual = decode(complete_json)
  inspect(actual, content="Array([False])")
}

///|
test "batch y_array_heterogeneous" {
  let complete_json =
    #|[null, 1, "1", {}]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([Null, Number(1), String("1"), Object({})])
    ),
  )
}

///|
test "batch y_array_null" {
  let complete_json =
    #|[null]
  let actual = decode(complete_json)
  inspect(actual, content="Array([Null])")
}

///|
test "batch y_array_with_1_and_newline" {
  let complete_json =
    #|[1\n]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_array_with_leading_space" {
  let complete_json =
    #| [1]
  let actual = decode(complete_json)
  inspect(actual, content="Array([Number(1)])")
}

///|
test "batch y_array_with_several_null" {
  let complete_json =
    #|[1,null,null,null,2]
  let actual = decode(complete_json)
  inspect(actual, content="Array([Number(1), Null, Null, Null, Number(2)])")
}

///|
test "batch y_array_with_trailing_space" {
  let complete_json =
    #|[2] 
  let actual = decode(complete_json)
  inspect(actual, content="Array([Number(2)])")
}

///|
test "batch y_number_0e+1" {
  let complete_json =
    #|[0e+1]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_number_0e1" {
  let complete_json =
    #|[0e1]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_number_after_space" {
  let complete_json =
    #|[ 4]
  let actual = decode(complete_json)
  inspect(actual, content="Array([Number(4)])")
}

///|
test "batch y_number_double_close_to_zero" {
  let complete_json =
    #|[-0.000000000000000000000000000000000000000000000000000000000000000000000000000001]
  let actual = decode(complete_json)
  inspect(actual, content="Array([Number(-1e-78)])")
}

///|
test "batch y_number_int_with_exp" {
  let complete_json =
    #|[20e1]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_number" {
  let complete_json =
    #|[123e65]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_number_minus_zero" {
  let complete_json =
    #|[-0]
  let actual = decode(complete_json)
  inspect(actual, content="Array([Number(0)])")
}

///|
test "batch y_number_negative_int" {
  let complete_json =
    #|[-123]
  let actual = decode(complete_json)
  inspect(actual, content="Array([Number(-123)])")
}

///|
test "batch y_number_negative_one" {
  let complete_json =
    #|[-1]
  let actual = decode(complete_json)
  inspect(actual, content="Array([Number(-1)])")
}

///|
test "batch y_number_negative_zero" {
  let complete_json =
    #|[-0]
  let actual = decode(complete_json)
  inspect(actual, content="Array([Number(0)])")
}

///|
test "batch y_number_real_capital_e" {
  let complete_json =
    #|[1E22]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_number_real_capital_e_neg_exp" {
  let complete_json =
    #|[1E-2]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_number_real_capital_e_pos_exp" {
  let complete_json =
    #|[1E+2]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_number_real_exponent" {
  let complete_json =
    #|[123e45]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_number_real_fraction_exponent" {
  let complete_json =
    #|[123.456e78]
  let actual = decode(complete_json)
  inspect(actual, content="Array([Number(1.23456e+80)])")
}

///|
test "batch y_number_real_neg_exp" {
  let complete_json =
    #|[1e-2]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_number_real_pos_exponent" {
  let complete_json =
    #|[1e+2]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_number_simple_int" {
  let complete_json =
    #|[123]
  let actual = decode(complete_json)
  inspect(actual, content="Array([Number(123)])")
}

///|
test "batch y_number_simple_real" {
  let complete_json =
    #|[123.456789]
  let actual = decode(complete_json)
  inspect(actual, content="Array([Number(123.456789)])")
}

///|
test "batch y_object_basic" {
  let complete_json =
    #|{"asd":"sdf"}
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Object({"asd": String("sdf")})
    ),
  )
}

///|
test "batch y_object_duplicated_key_and_value" {
  let complete_json =
    #|{"a":"b","a":"b"}
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Object({"a": String("b")})
    ),
  )
}

///|
test "batch y_object_duplicated_key" {
  let complete_json =
    #|{"a":"b","a":"c"}
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Object({"a": String("c")})
    ),
  )
}

///|
test "batch y_object_empty" {
  let complete_json =
    #|{}
  let actual = decode(complete_json)
  inspect(actual, content="Object({})")
}

///|
test "batch y_object_empty_key" {
  let complete_json =
    #|{"":0}
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Object({"": Number(0)})
    ),
  )
}

///|
test "batch y_object_escaped_null_in_key" {
  let complete_json =
    #|{"foo\u0000bar": 42}
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Object({"foo\\u0000bar": Number(42)})
    ),
  )
}

///|
test "batch y_object_extreme_numbers" {
  let complete_json =
    #|{ "min": -1.0e+28, "max": 1.0e+28 }
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Object({"min": Number(-1e+28), "max": Number(1e+28)})
    ),
  )
}

///|
test "batch y_object" {
  let complete_json =
    #|{"asd":"sdf", "dfg":"fgh"}
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Object({"asd": String("sdf"), "dfg": String("fgh")})
    ),
  )
}

///|
test "batch y_object_long_strings" {
  let long_string = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  let complete_json =
    "{\"x\":[{\"id\": \"" +
    long_string +
    "\"}], \"id\": \"" +
    long_string +
    "\"}"
  let actual = decode(complete_json)
  let expected =
    "Object({\"x\": Array([Object({\"id\": String(\"" +
    long_string +
    "\")})]), \"id\": String(\"" +
    long_string +
    "\")})"
  inspect(actual, content=expected)
}

///|
test "batch y_object_simple" {
  let complete_json =
    #|{"a":[]}
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Object({"a": Array([])})
    ),
  )
}

///|
test "batch y_object_string_unicode" {
  let complete_json =
    #|{"title":"\u041f\u043e\u043b\u0442\u043e\u0440\u0430 \u0417\u0435\u043c\u043b\u0435\u043a\u043e\u043f\u0430" }
  let actual = decode(complete_json)
  let expected =
    "Object({\"title\": String(\"\\\\u041f\\\\u043e\\\\u043b\\\\u0442" +
    "\\\\u043e\\\\u0440\\\\u0430 \\\\u0417\\\\u0435\\\\u043c" +
    "\\\\u043b\\\\u0435\\\\u043a\\\\u043e\\\\u043f\\\\u0430\")})"
  inspect(actual, content=expected)
}

///|
test "batch y_object_with_newlines" {
  let complete_json =
    #|{\n"a": "b"\n}
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_string_1_2_3_bytes_UTF-8_sequences" {
  let complete_json =
    #|["\u0060\u012a\u12AB"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\u0060\\u012a\\u12AB")])
    ),
  )
}

///|
test "batch y_string_accepted_surrogate_pair" {
  let complete_json =
    #|["\uD801\udc37"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uD801\\udc37")])
    ),
  )
}

///|
test "batch y_string_accepted_surrogate_pairs" {
  let complete_json =
    #|["\ud83d\ude39\ud83d\udc8d"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\ud83d\\ude39\\ud83d\\udc8d")])
    ),
  )
}

///|
test "batch y_string_allowed_escapes" {
  let complete_json =
    #|["\"\\\/\b\f\n\r\t"]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_string_backslash_and_u_escaped_zero" {
  let complete_json =
    #|["\\u0000"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\\\u0000")])
    ),
  )
}

///|
test "batch y_string_backslash_doublequotes" {
  let complete_json =
    #|["\""]
  let actual = decode(complete_json)
  inspect(actual, content="")
}

///|
test "batch y_string_comments" {
  let complete_json =
    #|["a/*b*/c/*d//e"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("a/*b*/c/*d//e")])
    ),
  )
}

///|
test "batch y_string_double_escape_a" {
  let complete_json =
    #|["\\a"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\\\a")])
    ),
  )
}

///|
test "batch y_string_double_escape_n" {
  let complete_json =
    #|["\\n"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\\\n")])
    ),
  )
}

///|
test "batch y_string_escaped_control_character" {
  let complete_json =
    #|["\u0012"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\u0012")])
    ),
  )
}

///|
test "batch y_string_escaped_noncharacter" {
  let complete_json =
    #|["\uFFFF"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uFFFF")])
    ),
  )
}

///|
test "batch y_string_in_array" {
  let complete_json =
    #|["asd"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("asd")])
    ),
  )
}

///|
test "batch y_string_in_array_with_leading_space" {
  let complete_json =
    #|[ "asd"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("asd")])
    ),
  )
}

///|
test "batch y_string_last_surrogates_1_and_2" {
  let complete_json =
    #|["\uDBFF\uDFFF"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uDBFF\\uDFFF")])
    ),
  )
}

///|
test "batch y_string_nbsp_uescaped" {
  let complete_json =
    #|["new\u00A0line"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("new\\u00A0line")])
    ),
  )
}

///|
test "batch y_string_nonCharacterInUTF-8_U+10FFFF" {
  let complete_json =
    #|["ô¿¿"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("ô¿¿")])
    ),
  )
}

///|
test "batch y_string_nonCharacterInUTF-8_U+FFFF" {
  let complete_json =
    #|["ï¿¿"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("ï¿¿")])
    ),
  )
}

///|
test "batch y_string_null_escape" {
  let complete_json =
    #|["\u0000"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\u0000")])
    ),
  )
}

///|
test "batch y_string_one-byte-utf-8" {
  let complete_json =
    #|["\u002c"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\u002c")])
    ),
  )
}

///|
test "batch y_string_pi" {
  let complete_json =
    #|["Ï"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("Ï")])
    ),
  )
}

///|
test "batch y_string_reservedCharacterInUTF-8_U+1BFFF" {
  let complete_json =
    #|["ð¿¿"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("ð¿¿")])
    ),
  )
}

///|
test "batch y_string_simple_ascii" {
  let complete_json =
    #|["asd "]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("asd ")])
    ),
  )
}

///|
test "batch y_string_space" {
  let complete_json =
    #|" "
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|String(" ")
    ),
  )
}

///|
test "batch y_string_surrogates_U+1D11E_MUSICAL_SYMBOL_G_CLEF" {
  let complete_json =
    #|["\uD834\uDd1e"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uD834\\uDd1e")])
    ),
  )
}

///|
test "batch y_string_three-byte-utf-8" {
  let complete_json =
    #|["\u0821"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\u0821")])
    ),
  )
}

///|
test "batch y_string_two-byte-utf-8" {
  let complete_json =
    #|["\u0123"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\u0123")])
    ),
  )
}

///|
test "batch y_string_u+2028_line_sep" {
  let complete_json =
    #|["â¨"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("â¨")])
    ),
  )
}

///|
test "batch y_string_u+2029_par_sep" {
  let complete_json =
    #|["â©"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("â©")])
    ),
  )
}

///|
test "batch y_string_uescaped_newline" {
  let complete_json =
    #|["new\u000Aline"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("new\\u000Aline")])
    ),
  )
}

///|
test "batch y_string_uEscape" {
  let complete_json =
    #|["\u0061\u30af\u30EA\u30b9"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\u0061\\u30af\\u30EA\\u30b9")])
    ),
  )
}

///|
test "batch y_string_unescaped_char_delete" {
  let complete_json =
    #|[""]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("")])
    ),
  )
}

///|
test "batch y_string_unicode_2" {
  let complete_json =
    #|["âã´â"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("âã´â")])
    ),
  )
}

///|
test "batch y_string_unicodeEscapedBackslash" {
  let complete_json =
    #|["\u005C"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\u005C")])
    ),
  )
}

///|
test "batch y_string_unicode_escaped_double_quote" {
  let complete_json =
    #|["\u0022"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\u0022")])
    ),
  )
}

///|
test "batch y_string_unicode" {
  let complete_json =
    #|["\uA66D"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uA66D")])
    ),
  )
}

///|
test "batch y_string_unicode_U+10FFFE_nonchar" {
  let complete_json =
    #|["\uDBFF\uDFFE"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uDBFF\\uDFFE")])
    ),
  )
}

///|
test "batch y_string_unicode_U+1FFFE_nonchar" {
  let complete_json =
    #|["\uD83F\uDFFE"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uD83F\\uDFFE")])
    ),
  )
}

///|
test "batch y_string_unicode_U+200B_ZERO_WIDTH_SPACE" {
  let complete_json =
    #|["\u200B"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\u200B")])
    ),
  )
}

///|
test "batch y_string_unicode_U+2064_invisible_plus" {
  let complete_json =
    #|["\u2064"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\u2064")])
    ),
  )
}

///|
test "batch y_string_unicode_U+FDD0_nonchar" {
  let complete_json =
    #|["\uFDD0"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uFDD0")])
    ),
  )
}

///|
test "batch y_string_unicode_U+FFFE_nonchar" {
  let complete_json =
    #|["\uFFFE"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("\\uFFFE")])
    ),
  )
}

///|
test "batch y_string_utf8" {
  let complete_json =
    #|["â¬ð"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("â¬ð")])
    ),
  )
}

///|
test "batch y_string_with_del_character" {
  let complete_json =
    #|["aa"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("aa")])
    ),
  )
}

///|
test "batch y_structure_lonely_false" {
  let complete_json =
    #|false
  let actual = decode(complete_json)
  inspect(actual, content="False")
}

///|
test "batch y_structure_lonely_int" {
  let complete_json =
    #|42
  let actual = decode(complete_json)
  inspect(actual, content="Number(42)")
}

///|
test "batch y_structure_lonely_negative_real" {
  let complete_json =
    #|-0.1
  let actual = decode(complete_json)
  inspect(actual, content="Number(-0.1)")
}

///|
test "batch y_structure_lonely_null" {
  let complete_json =
    #|null
  let actual = decode(complete_json)
  inspect(actual, content="Null")
}

///|
test "batch y_structure_lonely_string" {
  let complete_json =
    #|"asd"
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|String("asd")
    ),
  )
}

///|
test "batch y_structure_lonely_true" {
  let complete_json =
    #|true
  let actual = decode(complete_json)
  inspect(actual, content="True")
}

///|
test "batch y_structure_string_empty" {
  let complete_json =
    #|""
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|String("")
    ),
  )
}

///|
test "batch y_structure_trailing_newline" {
  let complete_json =
    #|["a"]
  let actual = decode(complete_json)
  inspect(
    actual,
    content=(
      #|Array([String("a")])
    ),
  )
}

///|
test "batch y_structure_true_in_array" {
  let complete_json =
    #|[true]
  let actual = decode(complete_json)
  inspect(actual, content="Array([True])")
}

///|
test "batch y_structure_whitespace_array" {
  let complete_json =
    #| [] 
  let actual = decode(complete_json)
  inspect(actual, content="Array([])")
}

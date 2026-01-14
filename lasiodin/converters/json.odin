package converters

import os "core:os/os2"
import "core:io"
import "core:bufio"
import "core:mem"
import "core:strings"
import "core:encoding/json"
import "core:fmt"
import ls "../../lasiodin"

// Specification :: enum {
// 	JSON,
// 	JSON5, // https://json5.org/
// 	SJSON, // https://bitsquid.blogspot.com/2009/10/simplified-json-notation.html
// 	Bitsquid = SJSON,
// 	MJSON = SJSON,
// }
//
// Marshal_Options :: struct {
// 	// output based on spec
// 	spec: Specification,
//
// 	// Use line breaks & tabs/spaces
// 	pretty: bool,
//
// 	// Use spaces for indentation instead of tabs
// 	use_spaces: bool,
//
// 	// Given use_spaces true, use this many spaces per indent level. 0 means 4 spaces.
// 	spaces: int,
//
// 	// Output uint as hex in JSON5 & MJSON
// 	write_uint_as_hex: bool,
//
// 	// If spec is MJSON and this is true, then keys will be quoted.
// 	//
// 	// WARNING: If your keys contain whitespace and this is false, then the
// 	// output will be bad.
// 	mjson_keys_use_quotes: bool,
//
// 	// If spec is MJSON and this is true, then use '=' as delimiter between
// 	// keys and values, otherwise ':' is used.
// 	mjson_keys_use_equal_sign: bool,
//
// 	// When outputting a map, sort the output by key.
// 	//
// 	// NOTE: This will temp allocate and sort a list for each map.
// 	sort_maps_by_key: bool,
//
// 	// Output enum value's name instead of its underlying value.
// 	//
// 	// NOTE: If a name isn't found it'll use the underlying value.
// 	use_enum_names: bool,
//
// 	// Internal state
// 	indentation: int,
// 	mjson_skipped_first_braces_start: bool,
// 	mjson_skipped_first_braces_end: bool,
// }

to_json :: proc(
	stream: ^io.Stream,
	config: Converter_Configuration,
	las_data: ^ls.LasData,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	ok: Convert_Error,
) {

	return ok
}


@(private = "package")
write_to_json :: proc(
	stream: ^io.Stream,
	config: Converter_Configuration,
	las_data: ^ls.LasData,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	ok: Convert_Error,
) {
	json_data, json_err := json.marshal(las_data^, config.json_marshal_options)
	if (json_err != json.Marshal_Data_Error.None) || (json_err != io.Error.None) {
		fmt.eprintfln("Unable to marshal JSON: %v", json_err)
		return json_err
	}

	nb: int
	nb, ok = io.write_full(stream^, json_data)
	if ok != io.Error.None {
		fmt.eprintfln("Unable to write file: %v", ok)
		return ok
	}

	return nil
}


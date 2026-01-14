package main

import "core:os"
import "core:fmt"
import "core:encoding/json"
import ls "../../lasiodin"
import conv "../../lasiodin/converters"

main :: proc() {
	if !(len(os.args) >= 3) {
		fmt.eprintln("Require 2 files input!")
		fmt.eprintln("\t input 1: path to las file")
		fmt.eprintln("\t input 2: output path")
		return
	}

	file_name: string = os.args[1]
	las_file, parsed_ok := ls.load_las(file_name, allocator = context.allocator)
	if parsed_ok != nil {fmt.eprintfln("Failed to parse the data, err: %v", parsed_ok)}
	defer ls.delete_las_data(&las_file, allocator = context.allocator)

	out_name: string = os.args[2]
	ok_conv := conv.convert_las(
		out_name,
		{
			json_marshal_options = json.Marshal_Options {
				// Adds indentation etc
				pretty         = true,
				use_spaces     = true,
				// Output enum member names instead of numeric value.
				use_enum_names = true,
				indentation    = 0,
			},
		},
		&las_file,
		.JSON,
		allocator = context.allocator,
	)
	if ok_conv != nil {fmt.eprintfln("Failed to convert the data to JSON, err: %v", ok_conv)}

}


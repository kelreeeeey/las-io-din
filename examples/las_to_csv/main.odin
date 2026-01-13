package usage

import "core:os"
import "core:fmt"
import ls "../../lasiodin"
import conv "../../lasiodin/converters"

main :: proc() {
	if !(len(os.args) >= 3) {
		fmt.printf("Require 2 file input!")
		fmt.printf("\t input 1: path to las file")
		fmt.printf("\t input 2: output path")
		fmt.print("\n")
		return
	}

	file_name: string = os.args[1]
	las_file, parsed_ok := ls.load_las(file_name, allocator = context.allocator)
	defer ls.delete_las_data(&las_file, allocator = context.allocator)
	if parsed_ok != nil {fmt.printfln("Failed to parse the data, err: %v", parsed_ok)}

	out_name: string = os.args[2]
	ok_conv := conv.convert_las(
		out_name,
		{delimiter = string(","), line_separator = string("\n")},
		&las_file,
		.CSV,
		allocator = context.allocator,
	)
	if ok_conv != nil {fmt.printfln("Failed to convert the data to CSV, err: %v", ok_conv)}

}


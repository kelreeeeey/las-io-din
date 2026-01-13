package converters

import os "core:os/os2"
import    "core:io"
import    "core:bufio"
import    "core:mem"
import    "core:strings"
import    "core:fmt"
import ls "../../lasiodin"

to_json       :: proc(
	las_data : ^ls.LasData,
	allocator := context.allocator,
	loc := #caller_location) -> (ok: Convert_Error)
{

	return ok
}


@(private="package")
write_to_json :: proc(writer: ^bufio.Writer, stream: ^io.Stream, config:Converter_Configuration, las_data : ^ls.LasData, allocator := context.allocator, loc := #caller_location) -> (ok: Convert_Error)
{
	fmt.printfln("converting %v to json ...", las_data.file_name)
	return ok
}

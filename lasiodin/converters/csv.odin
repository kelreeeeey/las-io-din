package converters

import "base:runtime"
import "core:bufio"
import "core:fmt"
import "core:io"
import "core:mem"
import os "core:os/os2"
import "core:reflect"
import "core:strings"

import ls "../../lasiodin"

to_csv :: proc(
	las_data: ^ls.LasData,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	ok: Convert_Error,
) {
	return ok
}

@(private = "package")
write_to_csv :: proc(
	writer: ^bufio.Writer,
	stream: ^io.Stream,
	config: Converter_Configuration,
	las_data: ^ls.LasData,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	ok: Convert_Error,
) {

	nb: int // n bytes the stream has written

	{ 	// writing header dynamically.
		using las_data
		c: int

		c = 0
		n := int(curve_info.len)
		for c < n - 1 {
			nb, ok = io.write_string(stream^, curve_info.curves[c].mnemonic)
			if ok != io.Error.None do return ok
			nb, ok = io.write_string(stream^, config.delimiter)
			if ok != io.Error.None do return ok
			c += 1
		}
		nb, ok = io.write_string(stream^, curve_info.curves[c].mnemonic)
		if ok != io.Error.None do return ok
		nb, ok = io.write_string(stream^, config.line_separator)
		if ok != io.Error.None do return ok
	}

	log_data := las_data.log_data
	n_rows := log_data.nrows
	n_curves := cast(int)log_data.ncurves

	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)
	for row: i32 = 0; row < n_rows; row += 1 {

		for idx: int = 0; idx < n_curves - 1; idx += 1 {
			fmt.print()
			strings.write_f64(&builder, log_data.logs[idx][row], u8('F'))
			strings.write_string(&builder, config.delimiter)
		}
		strings.write_f64(&builder, log_data.logs[n_curves - 1][row], u8('F'))
		if row < n_rows - 1 {strings.write_string(&builder, config.line_separator)}
	}
	nb, ok = io.write_string(stream^, strings.to_string(builder))
	if ok != io.Error.None do return ok

	return nil
}


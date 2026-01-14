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

@(private = "package")
to_csv :: proc(
	stream: ^io.Stream,
	config: Converter_Configuration,
	las_data: ^ls.LasData,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	csv_string: string,
	ok: Convert_Error,
) {

	nb: int // n bytes the stream has written
	log_data := las_data.log_data
	n_rows := log_data.nrows
	n_curves := cast(int)log_data.ncurves

	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)

	{ 	// build the header
		using las_data
		c: int = 0
		n := int(curve_info.len)
		for c < n - 1 {
			strings.write_string(&builder, curve_info.curves[c].mnemonic)
			strings.write_string(&builder, config.delimiter)
			c += 1
		}
		strings.write_string(&builder, curve_info.curves[c].mnemonic)
		strings.write_string(&builder, config.line_separator)
	}

	{ 	// build the rows
		for row: i32 = 0; row < n_rows; row += 1 {

			for idx: int = 0; idx < n_curves - 1; idx += 1 {
				strings.write_f64(&builder, log_data.logs[idx][row], u8('F'))
				strings.write_string(&builder, config.delimiter)
			}
			strings.write_f64(&builder, log_data.logs[n_curves - 1][row], u8('F'))
			if row < n_rows - 1 {strings.write_string(&builder, config.line_separator)}
		}
	}

	strings.write_string(&builder, config.line_separator)
	csv_string = strings.to_string(builder)
	nb, ok = io.write_string(stream^, csv_string)
	if ok != io.Error.None do return csv_string, ok

	return csv_string, nil
}

@(private = "package")
write_to_csv :: proc(
	stream: ^io.Stream,
	config: Converter_Configuration,
	las_data: ^ls.LasData,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	ok: Convert_Error,
) {

	nb: int // n bytes the stream has written
	log_data := las_data.log_data
	n_rows := log_data.nrows
	n_curves := cast(int)log_data.ncurves

	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)

	{ 	// build the header
		using las_data
		c: int = 0
		n := int(curve_info.len)
		for c < n - 1 {
			strings.write_string(&builder, curve_info.curves[c].mnemonic)
			strings.write_string(&builder, config.delimiter)
			c += 1
		}
		strings.write_string(&builder, curve_info.curves[c].mnemonic)
		strings.write_string(&builder, config.line_separator)
	}

	{ 	// build the rows
		for row: i32 = 0; row < n_rows; row += 1 {

			for idx: int = 0; idx < n_curves - 1; idx += 1 {
				strings.write_f64(&builder, log_data.logs[idx][row], u8('F'))
				strings.write_string(&builder, config.delimiter)
			}
			strings.write_f64(&builder, log_data.logs[n_curves - 1][row], u8('F'))
			if row < n_rows - 1 {strings.write_string(&builder, config.line_separator)}
		}
	}

	strings.write_string(&builder, config.line_separator)
	csv_string := strings.to_string(builder)
	nb, ok = io.write_string(stream^, csv_string)
	if ok != io.Error.None do return ok

	return nil
}


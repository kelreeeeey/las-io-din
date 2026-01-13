package converters

import "base:runtime"
import "core:bufio"
import "core:fmt"
import "core:io"
import "core:mem"
import os "core:os"

import ls "../../lasiodin"

Converter_Target_Flags :: enum {
	CSV,
	JSON,
}

Converter_Configuration :: struct {
	// csv config
	delimiter:      string,
	line_separator: string,

	// json config
	flatten_log:    bool,
}

Convert_Error :: union {
	mem.Allocator_Error,
	os.Error,
	io.Error,
	bool, // general bool error
	Config_Error,
}


Config_Error :: struct {
	t: Config_Error_Type,
	m: string,
}
Config_Error_Type :: enum {
	CCSV_DELIMITER_MISSING,
	CCSV_LINE_SEPARATOR_MISSING,
	CCSV_DELIMITER_AND_LINE_SEPARATOR_ERROR,
	// CJSON_CONFIG, // TODO(Rey):
}


convert_las :: proc(
	out_path: string,
	config: Converter_Configuration,
	las_data: ^ls.LasData,
	flag: Converter_Target_Flags,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	ok: Convert_Error,
) {
	handle, open_error := os.open(out_path, os.O_CREATE | os.O_WRONLY)
	if open_error != os.ERROR_NONE {return open_error}
	stream := os.stream_from_handle(handle)

	// create a writer
	writer, io_ok := io.to_writer(stream)
	defer io.destroy(writer)
	if !io_ok {return io_ok}

	// define bufio_reader
	bufio_writer: bufio.Writer
	bufio.writer_init(&bufio_writer, writer, allocator = allocator)
	defer bufio.writer_destroy(&bufio_writer)

	switch flag {
	case .CSV:
		{
			using config
			if delimiter == "" do return Config_Error{t = .CCSV_DELIMITER_MISSING, m = "delimiter should be set for CSV conversion"}
			if delimiter == line_separator do return Config_Error{t = .CCSV_LINE_SEPARATOR_MISSING, m = "delimiter and line separator can not be the same"}
			if line_separator == "" do return Config_Error{t = .CCSV_DELIMITER_AND_LINE_SEPARATOR_ERROR, m = "line separator should be set for CSV conversion"}
		}

		// TODO(Rey): figure out how to write these thing to a file
		ok = write_to_csv(
			&bufio_writer,
			&writer,
			config,
			las_data,
			allocator = allocator,
			loc = loc,
		)
		return ok
	case .JSON:
		{
			using config
			// TODO(Rey): what possible error in this case?
		}

		ok = write_to_json(
			&bufio_writer,
			&writer,
			config,
			las_data,
			allocator = allocator,
			loc = loc,
		)
		return ok

	}

	return nil

}


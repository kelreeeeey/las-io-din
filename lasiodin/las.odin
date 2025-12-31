#+feature dynamic-literals
package lasiodin

import "core:os"
import "core:io"
import "core:bufio"
import "core:mem"
import "core:math"
import "core:strings"
import "core:strconv"

@(private="package")
_NON_NUMERIC_CHARS :: `qwertyuiop[]\\asdfghjkl;'zxcvbnm/QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?!@#$%^&*()_=`

/* load_las

path_to_las_file: string = path to LAS file
bufreader_size: int = 4096, default buffer size,
allocator: runtime.Allocator = context.allocator,
*/
load_las :: proc(
	path_to_las_file: string,
	bufreader_size: int = bufio.DEFAULT_BUF_SIZE,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	las_data: LasData,
	err     : ReadFileError) {

	las_data.file_name = path_to_las_file
	// create an handler
	handle, open_error := os.open(path_to_las_file, os.O_RDONLY)
	if open_error != os.ERROR_NONE {
		return las_data, OpenError{path_to_las_file, open_error}
	}

	// create a stream
	stream := os.stream_from_handle(handle)

	// create a reader
	reader, ok := io.to_reader(stream)
	defer io.destroy(reader)
	if !ok {
		return las_data, ReaderCreationError{path_to_las_file, stream}
	}

	// define bufio_reader
	bufio_reader : bufio.Reader
	bufio.reader_init(&bufio_reader, reader, bufreader_size, allocator=allocator)
	bufio_reader.max_consecutive_empty_reads = 1
	defer bufio.reader_destroy(&bufio_reader)

	next_line:        string
	vers_parse_err:   ReadFileError
	defer delete(next_line)

	version_header:   Version
	version_header, next_line, vers_parse_err = parse_version_info(path_to_las_file, &bufio_reader, allocator=allocator)
	if vers_parse_err != nil {
		// delete(version_header.add)
		return las_data, vers_parse_err
	} else {
		las_data.version = version_header
	}


	well_info_header:      WellInformation
	params_info_header:    ParameterInformation
	curve_info_header:     CurveInformation
	others_info_header:    OtherInformation
	log_datas_info_header: LogData

	for vers_parse_err == nil {

		switch {

			case strings.contains(next_line, "~W"):
			well_info_header, next_line, vers_parse_err = parse_well_info(
				path_to_las_file,
				&bufio_reader,
				next_line,
				allocator=allocator)
			if vers_parse_err != nil { return las_data, vers_parse_err }
			else                     { las_data.well_info = well_info_header }

			case strings.contains(next_line, "~C"):
			curve_info_header, next_line, vers_parse_err = parse_curve_info(
				path_to_las_file,
				&bufio_reader,
				next_line,
				allocator=allocator,
				loc=loc,
			)
			if vers_parse_err != nil { delete(curve_info_header.curves); return las_data, vers_parse_err }
			else                     { las_data.curve_info = curve_info_header }

			case strings.contains(next_line, "~P"):
			params_info_header, next_line, vers_parse_err = parse_param_info(
				path_to_las_file,
				&bufio_reader,
				next_line,
				allocator=allocator,
				loc=loc,
			)
			if vers_parse_err != nil { delete(params_info_header.params); return las_data, vers_parse_err }
			else                     { las_data.parameter_info = params_info_header }

			case strings.contains(next_line, "~O"):
			others_info_header, next_line, vers_parse_err = parse_other_info(
				path_to_las_file,
				&bufio_reader,
				next_line,
				allocator=allocator,
				loc=loc,
			)
			if vers_parse_err != nil { return las_data, vers_parse_err }
			else                     { las_data.other_info = others_info_header }

			case strings.contains(next_line, "~A"):
			log_datas_info_header, next_line, vers_parse_err = parse_ascii_log_info(
				path_to_las_file,
				&bufio_reader,
				next_line,
				version_header,
				well_info_header,
				curve_info_header,
				allocator=allocator,
				loc=loc,
			)
			if vers_parse_err != nil { return las_data, vers_parse_err }
			else                     { las_data.log_data = log_datas_info_header }

			case len(next_line) == 0: return las_data, nil
		}
	}

	return las_data, nil
}


@(private="package")
parse_las_line :: proc(
	nline:      string,
	allocator:= context.allocator,
	loc:=       #caller_location
) -> (mnem, unit, value, desc: string, ok: bool) {

	unsplit_unit : []string
	reversed : string

	// split by the first dot
	line, er := strings.split_n(nline, ".", 2, allocator=allocator)
	if er != nil do return mnem, unit, value, desc, false

	mnem            = strings.trim_space(line[0])

	// split by the first space after dot, minimum of 2
	unsplit_unit, er = strings.split_n(line[1], " ", 2, allocator=allocator)
	if er != nil do return mnem, unit, value, desc, false
	unit             = len(unsplit_unit[0]) > 1 ? strings.trim_space(unsplit_unit[0]) : unsplit_unit[0]

	// then we reverse the string so we can split it by its last occurence of ":" character
	reversed    , er = strings.reverse(unsplit_unit[1],  allocator=allocator, loc=loc)
	if er != nil do return mnem, unit, value, desc, false
	if strings.contains(reversed, ": ") {
		unsplit_unit, er = strings.split_n(reversed, ": ", 2, allocator=allocator)
		if er != nil do return mnem, unit, value, desc, false
		if len(unsplit_unit) > 1 {
			value       , er = strings.reverse(unsplit_unit[1], allocator=allocator, loc=loc)
			if er != nil do return mnem, unit, value, desc, false
			desc        , er = strings.reverse(unsplit_unit[0], allocator=allocator, loc=loc)
			if er != nil do return mnem, unit, value, desc, false
			value            = strings.trim_space(value)
			desc            = strings.trim_space(desc)
			return mnem, unit, value, desc, true

		// directly setting value from the split
		} else 	{
			value       , er = strings.reverse(unsplit_unit[0], allocator=allocator, loc=loc)
			if er != nil do return mnem, unit, value, desc, false
			value            = strings.trim_space(value)
			return mnem, unit, value, desc, true
		}
	} else if strings.contains(reversed, " :") {
		unsplit_unit, er = strings.split_n(reversed, " :", 2, allocator=allocator)

		if er != nil do return mnem, unit, value, desc, false
		if len(unsplit_unit) > 1 {
			value       , er = strings.reverse(unsplit_unit[1], allocator=allocator, loc=loc)
			if er != nil do return mnem, unit, value, desc, false
			desc        , er = strings.reverse(unsplit_unit[0], allocator=allocator, loc=loc)
			if er != nil do return mnem, unit, value, desc, false
			value            = strings.trim_space(value)
			desc            = strings.trim_space(desc)
			return mnem, unit, value, desc, true
		// directly setting value from the split
		} else 	{
			value       , er = strings.reverse(unsplit_unit[0], allocator=allocator, loc=loc)
			if er != nil do return mnem, unit, value, desc, false
			value            = strings.trim_space(value)
			return mnem, unit, value, desc, true
		}

	} else {
		return mnem, unit, value, desc, true
	}

}


/*
Parse version info will make version struct and return next first line section
and a potential error.

Input:
- path_to_las_file: string, path_to_las_file that were being read by the stream and bufio reader
- reader:   ^bufio.Reader, pointer to bufio.Reader struct,
- allocatort: context.allocator

Output:
- version_header: Version, the `Version` struct
- next_line: string, the first line of next sections i.e. the section line itself
	after the version section being read
- err: ReadFileError union, the potential error


Note:
	parse_version_info should always come first, it does not take previous line.
*/
@(private="package")
parse_version_info :: proc(
	path_to_las_file: string,
	reader: ^bufio.Reader,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	version_header: Version,
	next_line:      string,
	err:            ReadFileError,
) {

	read_lines    := make([dynamic]string, 0, allocator=allocator)

	version_header.vers = HeaderItem{}
	version_header.wrap = HeaderItem{}
	version_header.add = []HeaderItem{}

	count_section := 0
	count_line    := 0
	clone_err : mem.Allocator_Error
	for {

		raw_line, read_bytes_err := bufio.reader_read_string(reader, '\n', allocator=allocator)
		// defer delete(raw_line, allocator=allocator)
		if strings.has_prefix(raw_line, "~") { count_section += 1 }
		if read_bytes_err == os.ERROR_EOF || count_section == 2 {
			next_line, clone_err = strings.clone(raw_line, allocator=allocator)
			if clone_err != nil { return version_header, next_line, clone_err } // TODO: (Kelrey) do better error propagation with more intuitive error message.
			break
		} else if read_bytes_err != nil {
			return version_header, next_line, ReaderReadByteError{file_name=path_to_las_file, reader=reader^}
		} else {
			len_line := len(raw_line)-2
			append(&read_lines, raw_line[:len_line])
			// append(&read_lines, strings.cut(raw_line, 0, len_line))
			count_line += 1

		}
	}

	{ // assign all the read lines to Version struct
		additionals := make([dynamic]HeaderItem, 0, allocator=allocator)
		min_item := 2
		count := 0
		is_comment_or_section: bool
		for item in read_lines {

			is_comment_or_section = strings.has_prefix(item, "#") || strings.has_prefix(item, "~") || len(item) == 0
			if is_comment_or_section do continue

			if !strings.has_prefix(item, "~") || !strings.has_prefix(item, "#-") {

				// if strings.has_prefix(item, "~") do continue
				mnemonic, _, value, descr, ok := parse_las_line(item, allocator=allocator, loc=loc)

				switch {
				case strings.contains(mnemonic, "VERS"):
				new_value:= strconv.atof(value)
				version_header.vers.mnemonic = mnemonic
				version_header.vers.value = new_value
				version_header.vers.descr = descr

				case strings.contains(mnemonic, "WRAP"):
				new_value: bool
				if value == "YES" { new_value = true }
				else              { new_value = false }
				version_header.wrap.mnemonic = mnemonic
				version_header.wrap.value = new_value
				version_header.wrap.descr = descr

				case :
				adds := HeaderItem{ mnemonic= mnemonic, value   = value, descr   = descr, }
				append(&additionals, adds)
				}

				count += 1
			} else {
				continue
			}
		}

		if count <= min_item { delete(additionals) }
		else { version_header.add = additionals[:] }

	}

	return version_header, next_line, nil
}

@(private="package")
parse_well_info :: proc(
	path_to_las_file: string,
	reader: ^bufio.Reader,
	prev_line: string,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	well_info_header: WellInformation,
	next_line:        string,
	err:              ReadFileError,
) {

	if !strings.has_prefix(prev_line, "~W") {
		return well_info_header, next_line, ParseHeaderError{
			file_name=path_to_las_file,
			line=prev_line,
			message="Line is not a valid WELL INFORMATION section, cannot proceed to parse",
		}
	}

	read_lines    := make([dynamic]string, 0, allocator=allocator)

	count_section := 1
	count_line    := 0
	clone_err : mem.Allocator_Error
	for {

		raw_line, read_bytes_err := bufio.reader_read_string(reader, '\n', allocator=allocator)
		// defer delete(raw_line, allocator=allocator)

		if strings.has_prefix(raw_line, "~") { count_section += 1 }
		if read_bytes_err == os.ERROR_EOF || count_section == 2 {

			next_line, clone_err = strings.clone(raw_line, allocator=allocator)
			// TODO: (Kelrey) do better error propagation with more intuitive
			// error message.
			if clone_err != nil { return well_info_header, next_line, clone_err }
			break

		} else if read_bytes_err != nil {

			return well_info_header, next_line, ReaderReadByteError{file_name=path_to_las_file, reader=reader^}

		} else {


			len_line := len(raw_line)-2
			next_line, clone_err = strings.clone(raw_line[:len_line], allocator=allocator)
			// TODO: (Kelrey) do better error propagation with more intuitive
			// error message.
			if clone_err != nil { return well_info_header, next_line, clone_err }
			append(&read_lines, next_line)
			count_line += 1

		}
	}

	well_info_header.items = make_map(map[int]HeaderItem, allocator=allocator, loc=loc)
	{ // assign all the read lines to `CurveInformation` struct

		count:int = 0

		for _item in read_lines {
			item : string
			is_prefix_newline: bool      = strings.has_prefix(_item, "\n")
			if is_prefix_newline do item = _item[1:]
			else                 do item = _item

			is_comment_or_section: bool = strings.has_prefix(item, "#") || strings.has_prefix(item, "~") || len(item) == 0
			if !is_comment_or_section {

			mnemonic, unit, raw_value, descr, rem := parse_las_line(item, allocator=allocator, loc=loc)

			if mnemonic == "NULL" {
				well_info_header.null.mnemonic = "NULL"
				well_info_header.null.value = strconv.atof(raw_value)
				well_info_header.null.unit = unit
				well_info_header.null.descr = descr
			} else {
				if !strings.contains_any(raw_value, _NON_NUMERIC_CHARS) {
					value := strconv.atof(raw_value)
					well_info_header.items[count]    = HeaderItem{
						value    = value,
						mnemonic = mnemonic,
						unit     = unit,
						descr    = descr,
					}
				} else {
					well_info_header.items[count]    = HeaderItem{
						value    = raw_value,
						mnemonic = mnemonic,
						unit     = unit,
						descr    = descr,
					}
				}

				count += 1

			}
			}




		}

		well_info_header.len = cast(i32)count

	}

	return well_info_header, next_line, nil
}

@(private="package")
parse_curve_info :: proc(
	path_to_las_file: string,
	reader: ^bufio.Reader,
	prev_line: string,
	allocator := context.allocator,
	loc := #caller_location
) -> (
	curves_info_header: CurveInformation,
	next_line:        string,
	err:              ReadFileError,
) {

	if !strings.has_prefix(prev_line, "~C") {
		return curves_info_header, next_line, ParseHeaderError{
			file_name=path_to_las_file,
			line=prev_line,
			message="Line is not a valid CURVES INFORMATION section, cannot proceed to parse",
		}
	}

	read_lines    := make([dynamic]string, 0, allocator=allocator)
	clone_err : mem.Allocator_Error

	count_section := 1
	count_line    := 0
	for {

		raw_line, read_bytes_err := bufio.reader_read_string(reader, '\n', allocator=allocator)
		next_line, clone_err = strings.clone(raw_line, allocator=allocator)
		// defer delete(raw_line, allocator=allocator)
		if strings.has_prefix(raw_line, "~") { count_section += 1 }
		if read_bytes_err == os.ERROR_EOF || count_section == 2 {
			if clone_err != nil { return curves_info_header, next_line, clone_err } // TODO: (Kelrey) do better error propagation with more intuitive error message.
			break
		} else if read_bytes_err != nil {
			return curves_info_header, next_line, ReaderReadByteError{file_name=path_to_las_file, reader=reader^}
		} else {
			len_line := len(raw_line)-2
			n, alloc_err := append(&read_lines, cast(string)( next_line[:len_line] ))
			count_line += 1
		}
	}

	{ // assign all the read lines to `CurveInformation` struct

		count:int = 0
		// items     := make_map(map[int]HeaderItem)//, 0, allocator=allocator)

		for _item in read_lines {
			item : string
			is_prefix_newline: bool      = strings.has_prefix(_item, "\n")
			if is_prefix_newline do item = _item[1:]
			else                 do item = _item

			is_comment_or_section: bool = strings.has_prefix(item, "#") || strings.has_prefix(item, "~") || len(item) == 0
			if is_comment_or_section do continue

			header_item : HeaderItem
			mnemonic, unit, value, descr, ok := parse_las_line(item, allocator=allocator, loc=loc)

			header_item.mnemonic = mnemonic
			header_item.unit     = unit
			header_item.value    = value
			header_item.descr    = descr

			curves_info_header.curves[count] = header_item

			count += 1

		}

		curves_info_header.len = cast(i32)count

	}

	return curves_info_header, next_line, nil
}

@(private="package")
parse_param_info :: proc(
	path_to_las_file:       string,
	reader:          ^bufio.Reader,
	prev_line:       string,
	allocator:=      context.allocator,
	loc :=           #caller_location
) -> (
	params_info_header: ParameterInformation,
	next_line:          string,
	err:                ReadFileError,
) {

	if !strings.has_prefix(prev_line, "~P") {
		return params_info_header, next_line, ParseHeaderError{
			file_name=path_to_las_file,
			line=prev_line,
			message="Line is not a valid PARAMETERS INFORMATION section, cannot proceed to parse",
		}
	}

	read_lines    := make([dynamic]string, 0, allocator=allocator)

	count_section := 0
	count_line    := 0
	if count_section != 1 {
		for {

			raw_line, read_bytes_err := bufio.reader_read_string(reader, '\n', allocator=allocator)

			if strings.has_prefix(raw_line, "~") { count_section += 1 }

			if read_bytes_err == os.ERROR_EOF || count_section == 1 {

				clone_err : mem.Allocator_Error
				next_line, clone_err = strings.clone(raw_line, allocator = 	allocator)
				if clone_err != nil { return params_info_header, next_line, clone_err } // TODO: (Kelrey) do better error propagation with more intuitive error message.
				break

			} else if read_bytes_err != nil {

				return params_info_header, next_line, ReaderReadByteError{file_name=path_to_las_file, reader=reader^}

			} else {

				len_line := len(raw_line)-2
				append(&read_lines, raw_line[:len_line])
				count_line += 1

			}
		}
	}

	{ // assign all the read lines to `CurveInformation` struct

		count:i32 = 0
		items     := make([dynamic]HeaderItem, 0, allocator=allocator)
		for item in read_lines {

			// skip lines that are comments and section's head
			if !( !strings.has_prefix(item, "#") && !strings.has_prefix(item, "~") ) do continue

			mnemonic, unit, raw_value, descr, ok := parse_las_line(item, allocator = allocator, loc=loc)

			// NOTE: Check if the strings should be a numeric value or
			// just a plain ahh string.
			value: ItemValues
			if strings.contains_any(raw_value, "-0123456789") {
				value = strconv.atof(raw_value)
			} else {
				value = raw_value
			}

			header_item := HeaderItem{
				mnemonic = mnemonic,
				unit     = unit,
				value    = value,
				descr    = descr,
			}

			append(&items, header_item)
			count += 1

		}
		params_info_header.len = count
		params_info_header.params = items[:]
	}

	return params_info_header, next_line, nil
}

@(private="package")
parse_other_info :: proc(
	path_to_las_file: string,
	reader: ^bufio.Reader,
	prev_line: string,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	others_info_header: OtherInformation,
	next_line:          string,
	err:                ReadFileError,
) {

	if !strings.contains(prev_line, "~O") {
		return others_info_header, next_line, ParseHeaderError{
			file_name=path_to_las_file,
			line=prev_line,
			message="Line is not a valid OTHERS INFORMATION section, cannot proceed to parse",
		}
	}

	read_lines    := make([dynamic]string, 0, allocator=allocator)

	count_section := 1
	count_line    := 0
	for {

		raw_line, read_bytes_err := bufio.reader_read_string(reader, '\n', allocator=allocator)
		if strings.contains(raw_line, "~") { count_section += 1 }
		if read_bytes_err == os.ERROR_EOF || count_section == 2 {

			clone_err : mem.Allocator_Error
			next_line, clone_err = strings.clone(raw_line, allocator=allocator)
			// TODO: (Kelrey) do better error propagation with more intuitive
			// error message.
			if clone_err != nil { return others_info_header, next_line, clone_err }
			break

		} else if read_bytes_err != nil {

			return others_info_header, next_line, ReaderReadByteError{file_name=path_to_las_file, reader=reader^}

		} else {


			len_line := len(raw_line)-2
			append(&read_lines, raw_line[:len_line])

			count_line += 1

		}

	}

	{ // assign all the read lines to `OtherInformation` struct

		count:i32 = 0
		items     := make([dynamic]string, 0, allocator=allocator)
		for item in read_lines {
			if !strings.has_prefix(item, "#") {
				append(&items, item)
				count += 1
			} else { continue }

		}
		others_info_header.len  = count
		others_info_header.info = items[:]
	}

	return others_info_header, next_line, nil
}

@(private="package")
parse_ascii_log_info :: proc(
	path_to_las_file:      string,
	reader:         ^bufio.Reader,
	prev_line:      string,
	version_header: Version,
	well_info:      WellInformation,
	curve_header:   CurveInformation,
	allocator:=     context.allocator,
	loc:=           #caller_location
) -> (

	ascii_data:     LogData,
	next_line:      string,
	err:            ReadFileError,

) {

	ascii_data.wrap = version_header.wrap.value.(bool)
	if !strings.has_prefix(prev_line, "~A") {
		return ascii_data, next_line, ParseHeaderError{
			file_name=path_to_las_file,
			line=prev_line,
			message="Line is not a valid ASCII LOG DATA section, cannot proceed to parse",
		}
	}

	read_lines    := make([dynamic]string, 0, allocator=allocator)
	defer delete(read_lines)

	count_section := 1
	count_line    := 0
	for {

		raw_line, read_bytes_err := bufio.reader_read_string(reader, '\n', allocator=allocator)
		if read_bytes_err == os.ERROR_EOF {
			break
		} else if read_bytes_err != nil {
			return ascii_data, next_line, ReaderReadByteError{file_name=path_to_las_file, reader=reader^}
		} else {

				if strings.contains(raw_line, "~") { count_section += 1 }
				len_line := len(raw_line)-1
				if count_line == 0 { append(&read_lines, raw_line[:len_line-1]) }
				else               { append(&read_lines, raw_line[:len_line-1]) }
				count_line += 1

		}

	}

	n_curve_int:       = cast(int)curve_header.len
	ascii_data.ncurves = curve_header.len

	{ // assign all the read lines to `LogData` struct

		count:i32 = 0
		items     := make_map(map[int][]f64, allocator=allocator)
		container := make([][dynamic]f64, n_curve_int, allocator=allocator)

		if !ascii_data.wrap { // if it is not a wrapped version
			for item in read_lines {
				if strings.has_prefix(item, "#") do continue
				datum_points := parse_datum_points(item, allocator=allocator, loc=loc)
				for curve_idx in 0..<n_curve_int {
					point := strconv.atof(datum_points[curve_idx])
					append(&(container[curve_idx]), point)
				}
				count += 1

			}

		} else { // it is a wrapped version

			point:      f64
			is_first:   bool

			inner_count: = 1

			parse_line: for item in read_lines {

				datum_points     := parse_datum_points(item, allocator=allocator, loc=loc)
				sub_curve_length := len(datum_points)

				// setting the flag
				if sub_curve_length == 1 {

					is_first    = true
					point = strconv.atof(datum_points[0])
					append(&container[0], point)
					count += 1

				} else if sub_curve_length > 1 {

					is_first          = false
					sub_curve_idx    := 0

					for curve_idx in sub_curve_idx..<sub_curve_length {
						point = strconv.atof(datum_points[curve_idx])
						append(&(container[curve_idx+inner_count]), point)
					}

				} else {

					is_first = false
					continue parse_line

				}

				if !is_first { inner_count += sub_curve_length }
				else         { inner_count  = 1 }

			}

		}

		for idx in 0..<n_curve_int { items[idx] = container[idx][:] }

		ascii_data.nrows = count
		ascii_data.logs  = items

	}


	return ascii_data, next_line, nil
}

@(private="package")
parse_datum_points_no_wrapped :: proc(
	ascii_log_line: string,
	allocator:=     context.allocator,
	loc:=           #caller_location
) -> []string {
	raw_datum_points := strings.split(ascii_log_line, " ", allocator=allocator)
	
	datum_points:= make([dynamic]string, allocator=allocator)

	for datum in raw_datum_points {
		if len(datum) >= 1 {
			append(&datum_points, datum)
		}
	}

	return datum_points[:]
}

@(private="package")
parse_datum_points_wrapped :: proc(
	ascii_log_line: string,
	n_curve_int: int,
	allocator:=     context.allocator,
	loc:=           #caller_location
) -> []string {
	raw_datum_points := strings.split_n(ascii_log_line, " ", n_curve_int, allocator=allocator)

	datum_points:= make([dynamic]string, allocator=allocator)

	parse_datum: for datum in raw_datum_points {
		if datum != " " || datum != "" {
			append(&datum_points, datum)
		} else {
			continue parse_datum
		}
	}

	return datum_points[:]
}

@(private="package")
parse_datum_points :: proc {
	parse_datum_points_no_wrapped,
	parse_datum_points_wrapped,
}


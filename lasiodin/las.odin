#+feature dynamic-literals
package lasiodin

// import "base:runtime"
import "core:os"
import "core:io"
import "core:bufio"
import "core:mem"
import "core:math"
import "core:strings"
import "core:strconv"
// import "core:encoding/endian"

_NON_NUMERIC_CHARS :: `qwertyuiop[]\\asdfghjkl;'zxcvbnm/QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?!@#$%^&*()_=`

load_las :: proc(
	file_name: string,
	bufreader_size: int,
	allocator := context.allocator,
	temp_allocator := context.temp_allocator,
	loc := #caller_location,
) -> (
	las_data: LasData,
	err     : ReadFileError) {

	las_data.file_name = file_name
	// create an handler
	handle, open_error := os.open(file_name, os.O_RDONLY)
	if open_error != os.ERROR_NONE {
		return las_data, OpenError{file_name, open_error}
	}

	// create a stream
	stream := os.stream_from_handle(handle)

	// create a reader
	reader, ok := io.to_reader(stream)
	defer io.destroy(reader)
	if !ok {
		return las_data, ReaderCreationError{file_name, stream}
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
	version_header, next_line, vers_parse_err = parse_version_info(file_name, &bufio_reader, allocator=allocator)
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
				file_name,
				&bufio_reader,
				next_line,
				allocator=allocator)
			if vers_parse_err != nil { return las_data, vers_parse_err }
			else                     { las_data.well_info = well_info_header }

			case strings.contains(next_line, "~C"):
			curve_info_header, next_line, vers_parse_err = parse_curve_info(
				file_name,
				&bufio_reader,
				next_line,
				allocator=allocator,
				temp_allocator=temp_allocator,
				loc=loc,
			)
			if vers_parse_err != nil { delete(curve_info_header.curves); return las_data, vers_parse_err }
			else                     { las_data.curve_info = curve_info_header }

			case strings.contains(next_line, "~P"):
			params_info_header, next_line, vers_parse_err = parse_param_info(
				file_name,
				&bufio_reader,
				next_line,
				allocator=allocator,
				temp_allocator=temp_allocator,
				loc=loc,
			)
			if vers_parse_err != nil { delete(params_info_header.params); return las_data, vers_parse_err }
			else                     { las_data.parameter_info = params_info_header }

			case strings.contains(next_line, "~O"):
			others_info_header, next_line, vers_parse_err = parse_other_info(
				file_name,
				&bufio_reader,
				next_line,
				allocator=allocator,
				temp_allocator=temp_allocator,
				loc=loc,
			)
			if vers_parse_err != nil { return las_data, vers_parse_err }
			else                     { las_data.other_info = others_info_header }

			case strings.contains(next_line, "~A"):
			log_datas_info_header, next_line, vers_parse_err = parse_ascii_log_info(
				file_name,
				&bufio_reader,
				next_line,
				version_header,
				well_info_header,
				curve_info_header,
				allocator=allocator,
				temp_allocator=temp_allocator,
				loc=loc,
			)
			if vers_parse_err != nil { return las_data, vers_parse_err }
			else                     { las_data.log_data = log_datas_info_header }

			case len(next_line) == 0: return las_data, nil
		}
	}

	return las_data, nil
}


parse_las_line :: proc(
	nline:      string,
	allocator:= context.temp_allocator,
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
- file_name: string, file_name that were being read by the stream and bufio reader
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
parse_version_info :: proc(
	file_name: string,
	reader: ^bufio.Reader,
	allocator := context.allocator,
	temp_allocator := context.temp_allocator,
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
			return version_header, next_line, ReaderReadByteError{file_name=file_name, reader=reader^}
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

parse_well_info :: proc(
	file_name: string,
	reader: ^bufio.Reader,
	prev_line: string,
	allocator := context.allocator,
	temp_allocator := context.temp_allocator,
	loc := #caller_location,
) -> (
	well_info_header: WellInformation,
	next_line:        string,
	err:              ReadFileError,
) {

	if !strings.has_prefix(prev_line, "~W") {
		return well_info_header, next_line, ParseHeaderError{
			file_name=file_name,
			line=prev_line,
			message="Line is not a valid WELL INFORMATION section, cannot proceed to parse",
		}
	}

	read_lines    := make([dynamic]string, 0, allocator=allocator)

	count_section := 1
	count_line    := 0
	clone_err : mem.Allocator_Error
	for {

		raw_line, read_bytes_err := bufio.reader_read_string(reader, '\n', allocator=temp_allocator)
		// defer delete(raw_line, allocator=allocator)

		if strings.has_prefix(raw_line, "~") { count_section += 1 }
		if read_bytes_err == os.ERROR_EOF || count_section == 2 {

			next_line, clone_err = strings.clone(raw_line, allocator=temp_allocator)
			// TODO: (Kelrey) do better error propagation with more intuitive
			// error message.
			if clone_err != nil { return well_info_header, next_line, clone_err }
			break

		} else if read_bytes_err != nil {

			return well_info_header, next_line, ReaderReadByteError{file_name=file_name, reader=reader^}

		} else {


			len_line := len(raw_line)-2
			next_line, clone_err = strings.clone(raw_line[:len_line], allocator=temp_allocator)
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

			mnemonic, unit, raw_value, descr, rem := parse_las_line(item, allocator=temp_allocator, loc=loc)

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

parse_curve_info :: proc(
	file_name: string,
	reader: ^bufio.Reader,
	prev_line: string,
	allocator := context.allocator,
	temp_allocator := context.temp_allocator,
	loc := #caller_location
) -> (
	curves_info_header: CurveInformation,
	next_line:        string,
	err:              ReadFileError,
) {

	if !strings.has_prefix(prev_line, "~C") {
		return curves_info_header, next_line, ParseHeaderError{
			file_name=file_name,
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
			return curves_info_header, next_line, ReaderReadByteError{file_name=file_name, reader=reader^}
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

parse_param_info :: proc(
	file_name:       string,
	reader:          ^bufio.Reader,
	prev_line:       string,
	allocator:=      context.allocator,
	temp_allocator:= context.temp_allocator,
	loc :=           #caller_location
) -> (
	params_info_header: ParameterInformation,
	next_line:          string,
	err:                ReadFileError,
) {

	if !strings.has_prefix(prev_line, "~P") {
		return params_info_header, next_line, ParseHeaderError{
			file_name=file_name,
			line=prev_line,
			message="Line is not a valid PARAMETERS INFORMATION section, cannot proceed to parse",
		}
	}

	read_lines    := make([dynamic]string, 0, allocator=allocator)


	count_section := 0
	count_line    := 0
	if count_section != 1 {
		for {

			raw_line, read_bytes_err := bufio.reader_read_string(reader, '\n', allocator=temp_allocator)
			// defer delete(raw_line, allocator=allocator)

			if strings.has_prefix(raw_line, "~") { count_section += 1 }

			if read_bytes_err == os.ERROR_EOF || count_section == 1 {

				clone_err : mem.Allocator_Error
				next_line, clone_err = strings.clone(raw_line, allocator = 	temp_allocator)
				if clone_err != nil { return params_info_header, next_line, clone_err } // TODO: (Kelrey) do better error propagation with more intuitive error message.
				break

			} else if read_bytes_err != nil {

				return params_info_header, next_line, ReaderReadByteError{file_name=file_name, reader=reader^}

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

			mnemonic, unit, raw_value, descr, ok := parse_las_line(item, allocator = temp_allocator, loc=loc)

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

parse_other_info :: proc(
	file_name: string,
	reader: ^bufio.Reader,
	prev_line: string,
	allocator := context.allocator,
	temp_allocator := context.temp_allocator,
	loc := #caller_location,
) -> (
	others_info_header: OtherInformation,
	next_line:          string,
	err:                ReadFileError,
) {

	if !strings.contains(prev_line, "~O") {
		return others_info_header, next_line, ParseHeaderError{
			file_name=file_name,
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

			return others_info_header, next_line, ReaderReadByteError{file_name=file_name, reader=reader^}

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

parse_ascii_log_info :: proc(
	file_name:      string,
	reader:         ^bufio.Reader,
	prev_line:      string,
	version_header: Version,
	well_info:      WellInformation,
	curve_header:   CurveInformation,
	allocator:=     context.allocator,
	temp_allocator:=     context.temp_allocator,
	loc:=           #caller_location
) -> (

	ascii_data:     LogData,
	next_line:      string,
	err:            ReadFileError,

) {

	ascii_data.wrap = version_header.wrap.value.(bool)
	if !strings.has_prefix(prev_line, "~A") {
		return ascii_data, next_line, ParseHeaderError{
			file_name=file_name,
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
			return ascii_data, next_line, ReaderReadByteError{file_name=file_name, reader=reader^}
		} else {

			if strings.contains(raw_line, "~") { count_section += 1 }
			len_line := len(raw_line)-1
			if count_line == 0 { append(&read_lines, raw_line[:len_line]) }
			else               { append(&read_lines, raw_line[:len_line]) }

			count_line += 1
		}

	}

	n_curve_int:       = cast(int)curve_header.len
	// n_curve_non_first := n_curve_int-1
	ascii_data.ncurves = curve_header.len

	{ // assign all the read lines to `LogData` struct

		count:i32 = 0
		items     := make_map(map[int][]f64, allocator=allocator)
		container := make([][dynamic]f64, n_curve_int, allocator=allocator)
		// defer {
		// 	for c in container { delete(c) }
		// 	delete(container)
		// }

		if !ascii_data.wrap { // if it is not a wrapped version
			for item in read_lines {
				if strings.has_prefix(item, "#") do continue
				datum_points := parse_datum_points(item, allocator=allocator, loc=loc)
				for curve_idx in 0..<n_curve_int {
					point := strconv.atof(datum_points[curve_idx])
					if point == well_info.null.value { append(&(container[curve_idx]), math.nan_f64()) }
					else                             { append(&(container[curve_idx]), point) }
				}
				count += 1

			}

		} else { // it is a wrapped version

			point:      f64
			is_first:   bool

			inner_count: = 1

			for item in read_lines {

				datum_points     := parse_datum_points(item, allocator=allocator, loc=loc)
				sub_curve_length := len(datum_points)

				// setting the flag
				if sub_curve_length == 1 {

					is_first    = true
					point = strconv.atof(datum_points[0])
					append(&container[0], point)
					count += 1

				} else {

					is_first          = false
					sub_curve_idx    := 0

					for curve_idx in sub_curve_idx..<sub_curve_length {
						point = strconv.atof(datum_points[curve_idx])
						if point == well_info.null.value { append(&(container[curve_idx+inner_count]), math.nan_f64())
						} else { append(&(container[curve_idx+inner_count]), point) }
					}

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

parse_datum_points_wrapped :: proc(
	ascii_log_line: string,
	n_curve_int: int,
	allocator:=     context.allocator,
	loc:=           #caller_location
) -> []string {
	raw_datum_points := strings.split_n(ascii_log_line, " ", n_curve_int, allocator=allocator)

	datum_points:= make([dynamic]string, allocator=allocator)

	for datum in raw_datum_points {
		if datum != "" {
			append(&datum_points, datum)
		} else {
			append(&datum_points, "")
		}
	}

	return datum_points[:]
}

parse_datum_points :: proc {
	parse_datum_points_no_wrapped,
	parse_datum_points_wrapped,
}

import    "core:fmt"
import tt "core:testing"

@(test)
test_load_las_example_1_canadian_well_logging_society :: proc(t: ^tt.T) {
	las_file, parsed_ok := load_las(
		"assets/example_1_canadian_well_logging_society.las",
		4016,
		allocator=context.temp_allocator,
	)
	defer delete_las_data(las_file)
	tt.expect(t, parsed_ok == nil, fmt.tprint(parsed_ok))

	//  Version Section
	{   using las_file.version
		tt.expect(t, vers.mnemonic == "VERS",   fmt.tprint(vers.mnemonic))
		tt.expect(t, vers.unit     == "",       fmt.tprint(vers.unit))
		tt.expect(t, vers.value    == f64(2.0), fmt.tprint(vers.value))
		tt.expect(t, vers.descr    == "CWLS LOG ASCII STANDARD -VERSION 2.0", fmt.tprint(vers.descr))
		tt.expect(t, wrap.mnemonic == "WRAP", fmt.tprint(wrap.mnemonic))
		tt.expect(t, wrap.unit     == "",     fmt.tprint(wrap.unit))
		tt.expect(t, wrap.value    == false,  fmt.tprint(wrap.value))
		tt.expect(t, wrap.descr    == "ONE LINE PER DEPTH STEP", fmt.tprint(wrap.descr))
	}

	//  Well Information Section
	{   using las_file.well_info
		tt.expect(t, items[0].mnemonic == "STRT",        fmt.tprint(items[0].mnemonic))
		tt.expect(t, items[0].unit     == "M",           fmt.tprint(items[0].unit))
		tt.expect(t, items[0].value    == f64(1670.0),   fmt.tprint(items[0].value))
		tt.expect(t, items[0].descr    == "START DEPTH", fmt.tprint(items[0].descr))

		tt.expect(t, items[1].mnemonic == "STOP",         fmt.tprint(items[1].mnemonic))
		tt.expect(t, items[1].unit     == "M",            fmt.tprint(items[1].unit))
		tt.expect(t, items[1].value    == f64(1669.75),   fmt.tprint(items[1].value))
		tt.expect(t, items[1].descr    == "STOP DEPTH",   fmt.tprint(items[1].descr))
	}

	// tt.expect(t, slice.equal(np_tensor.shape, []uint{5, 5}))
}

@(test)
test_load_las_example_2_canadian_well_logging_society :: proc(t: ^tt.T) {
	las_file, parsed_ok := load_las(
		"assets/example_2_canadian_well_logging_society.las",
		4016,
		allocator=context.temp_allocator,
	)
	defer delete_las_data(las_file)
	tt.expect(t, parsed_ok == nil, fmt.tprint(parsed_ok))

	//  Version Section
	{   using las_file.version

		tt.expect(t, vers.mnemonic == "VERS",   fmt.tprint(vers.mnemonic))
		tt.expect(t, vers.unit     == "",       fmt.tprint(vers.unit))
		tt.expect(t, vers.value    == f64(2.0), fmt.tprint(vers.value))
		tt.expect(t, vers.descr    == "CWLS LAS-VERSION 2.0", fmt.tprint(vers.descr))

		tt.expect(t, wrap.mnemonic == "WRAP", fmt.tprint(wrap.mnemonic))
		tt.expect(t, wrap.unit     == "",     fmt.tprint(wrap.unit))
		tt.expect(t, wrap.value    == false,  fmt.tprint(wrap.value))
		tt.expect(t, wrap.descr    == "One line per depth step", fmt.tprint(wrap.descr))

	}

	//  Well Information Section
	{   using las_file.well_info

		tt.expect(t, items[0].mnemonic == "STRT",        fmt.tprint(items[0].mnemonic))
		tt.expect(t, items[0].unit     == "M",           fmt.tprint(items[0].unit))
		tt.expect(t, items[0].value    == f64(635.0000),   fmt.tprint(items[0].value))
		tt.expect(t, items[0].descr    == "START DEPTH", fmt.tprint(items[0].descr))

		tt.expect(t, items[1].mnemonic == "STOP",         fmt.tprint(items[1].mnemonic))
		tt.expect(t, items[1].unit     == "M",            fmt.tprint(items[1].unit))
		tt.expect(t, items[1].value    == f64(634.8750),  fmt.tprint(items[1].value))
		tt.expect(t, items[1].descr    == "STOP DEPTH",   fmt.tprint(items[1].descr))

		tt.expect(t, items[2].mnemonic == "STEP",         fmt.tprint(items[2].mnemonic))
		tt.expect(t, items[2].unit     == "M",            fmt.tprint(items[2].unit))
		tt.expect(t, items[2].value    == f64(-0.1250),   fmt.tprint(items[2].value))
		tt.expect(t, items[2].descr    == "STEP",         fmt.tprint(items[2].descr))

		tt.expect(t, null.mnemonic == "NULL",         fmt.tprint(null.mnemonic))
		tt.expect(t, null.unit     == "",             fmt.tprint(null.unit))
		tt.expect(t, null.value    == f64(-999.25),   fmt.tprint(null.value))
		tt.expect(t, null.descr    == "NULL VALUE",   fmt.tprint(null.descr))

		tt.expect(t, items[3].mnemonic == "COMP",                 fmt.tprint(items[3].mnemonic))
		tt.expect(t, items[3].unit     == "",                     fmt.tprint(items[3].unit))
		tt.expect(t, items[3].value    == "ANY OIL COMPANY INC.", fmt.tprint(items[3].value))
		tt.expect(t, items[3].descr    == "COMPANY",              fmt.tprint(items[3].descr))

		tt.expect(t, items[4].mnemonic == "WELL",                  fmt.tprint(items[4].mnemonic))
		tt.expect(t, items[4].unit     == "",                      fmt.tprint(items[4].unit))
		tt.expect(t, items[4].value    == "ANY ET AL 12-34-12-34", fmt.tprint(items[4].value))
		tt.expect(t, items[4].descr    == "WELL",                  fmt.tprint(items[4].descr))

		tt.expect(t, items[5].mnemonic == "FLD",     fmt.tprint(items[5].mnemonic))
		tt.expect(t, items[5].unit     == "",        fmt.tprint(items[5].unit))
		tt.expect(t, items[5].value    == "WILDCAT", fmt.tprint(items[5].value))
		tt.expect(t, items[5].descr    == "FIELD",   fmt.tprint(items[5].descr))

		tt.expect(t, items[6].mnemonic == "LOC",            fmt.tprint(items[6].mnemonic))
		tt.expect(t, items[6].unit     == "",               fmt.tprint(items[6].unit))
		tt.expect(t, items[6].value    == "12-34-12-34W5M", fmt.tprint(items[6].value))
		tt.expect(t, items[6].descr    == "LOCATION",       fmt.tprint(items[6].descr))

		tt.expect(t, items[7].mnemonic == "PROV",     fmt.tprint(items[7].mnemonic))
		tt.expect(t, items[7].unit     == "",         fmt.tprint(items[7].unit))
		tt.expect(t, items[7].value    == "ALBERTA",  fmt.tprint(items[7].value))
		tt.expect(t, items[7].descr    == "PROVINCE", fmt.tprint(items[7].descr))

	}

	// tt.expect(t, slice.equal(np_tensor.shape, []uint{5, 5}))
}

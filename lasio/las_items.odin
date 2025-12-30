package lasio

HeaderItem :: struct {
    mnemonic:          string,
    unit:              string,
    value:             ItemValues,
    descr:             string,
}

ItemValues :: union {
    string,
    f64,
    i64,
    bool,
}

// Sections
Version :: struct {
    vers: HeaderItem,
    wrap: HeaderItem,
    add:  []HeaderItem,
}

WellInformation :: struct {
    len: i32,
    items: map[int]HeaderItem,
    null: HeaderItem
}

@(private = "file")
delete_well_info :: proc(well_info: WellInformation) {
	delete_map(well_info.items)
}


// Curves
CurveInformation :: struct {
    len:    i32,
    curves: map[int]HeaderItem,
}

@(private = "file")
delete_curve_info :: proc(curve_info: CurveInformation) {
	delete_map(curve_info.curves)
}

// Parameter informations, non-mandatory
ParameterInformation :: struct {
    len:    i32,
    params: []HeaderItem,
}

@(private = "file")
delete_param_info :: proc(param_info: ParameterInformation) {
	delete(param_info.params)
}

// Other informations, non-mandatory
OtherInformation :: struct {
    len:  i32,
    info: []string,
}

delete_other_info :: proc(other_info: OtherInformation) {
	for info in other_info.info {
		delete(info)
	}
	delete (other_info.info)
}

// ASCII Log Data, non-mandatory
LogData :: struct {
    wrap:    bool,
    nrows:   i32,
    ncurves: i32,
    logs:    map[int][]f64,
}

delete_log_data :: proc(log_data: LogData) {
	delete_map(log_data.logs)
}


// Union of section
SectionType :: union {
    Version,
    WellInformation,
    CurveInformation,
    ParameterInformation,
    OtherInformation,
    LogData,
    []string,
}

FLAGS :: enum {
	TILDE, // `~` character, indicating section
	POUND, // `#` chatacter, indication comment
	OTHER, // ` ` or `\t` chatacters, indication data
}

SectionFlags :: enum {
    V, // version
    W, // well information
    C, // curve information
    P, // parameter information
    O, // other information
    A, // ascii log data
}


// LAS Data
Section :: struct {
    name:  string,
    flag:  SectionFlags,
    items: SectionType,
}

LasData :: struct {
    file_name:      string,
    version:        Version,
    well_info:      WellInformation,
    curve_info:     CurveInformation,
    parameter_info: ParameterInformation,
    other_info:     OtherInformation,
    log_data:       LogData,
}

delete_las_data :: proc(las_data: LasData, allocator:= context.allocator) {
	delete(las_data.version.add)
	delete_curve_info(las_data.curve_info)
	// delete_param_info(las_data.parameter_info)

	well_info := las_data.well_info
	clear(&well_info.items)
	// delete(las_data.well_info.items)

	curve_info := las_data.curve_info
	clear(&curve_info.curves)
	// delete(las_data.curve_info.curves)

	// delete(las_data.parameter_info.params)
	// delete(las_data.other_info.info, allocator=allocator)

	for _, log in las_data.log_data.logs {
		delete(log, allocator=allocator)
	}
	delete(las_data.log_data.logs)
	// for key, log in las_data.log_data.logs {
	// 	delete_key(key)
	// 	delete(log)
	// }
}

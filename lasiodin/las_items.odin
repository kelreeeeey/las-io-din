package lasiodin

import "core:mem"
import "base:intrinsics"

ItemValues :: union {
	string,
	f64,
	i64,
	bool,
}

HeaderItem :: struct {
	mnemonic: string,
	unit:     string,
	value:    ItemValues,
	descr:    string,
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

// Sections
Version :: struct {
	vers: HeaderItem,
	wrap: HeaderItem,
	add:  []HeaderItem,
}

WellInformation :: struct {
	len:   i32,
	items: map[int]HeaderItem,
	null:  HeaderItem,
}

CurveInformation :: struct {
	len:    i32,
	curves: map[int]HeaderItem,
}

// Parameter informations, non-mandatory
ParameterInformation :: struct {
	len:    i32,
	params: []HeaderItem,
}

// Other informations, non-mandatory
OtherInformation :: struct {
	len:  i32,
	info: []string,
}

// ASCII Log Data
LogData :: struct {
	wrap:    bool,
	nrows:   i32,
	ncurves: i32,
	logs:    map[int][]f64,
}


delete_las_data :: proc(las_data: ^LasData, allocator := context.allocator) {
	if len(las_data.version.add) > 0 do delete(las_data.version.add, allocator = allocator)

	well_info := las_data.well_info
	clear(&well_info.items)

	curve_info := las_data.curve_info
	clear(&curve_info.curves)
	delete_map(curve_info.curves)

	// for _, curve in las_data.log_data.logs { delete(log, allocator=allocator) }
	// delete(las_data.curve_info.logs)

	for _, log in las_data.log_data.logs {delete(log, allocator = allocator)}
	delete(las_data.log_data.logs)

}


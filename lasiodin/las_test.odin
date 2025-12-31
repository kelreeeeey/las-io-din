package lasiodin

import    "core:fmt"
import tt "core:testing"
import    "core:slice"

@(test)
test_load_las_example_1_canadian_well_logging_society :: proc(t: ^tt.T) {
	las_file, parsed_ok := load_las(
		"assets/example_1_canadian_well_logging_society.las",
		allocator=context.temp_allocator,
	)
	defer delete_las_data(&las_file)
	tt.expect(t, parsed_ok == nil, fmt.tprint(parsed_ok))


	NaN := f64(-999.25)
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
		allocator=context.temp_allocator,
	)
	defer delete_las_data(&las_file)
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

	NaN := f64(-999.25)
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
		tt.expect(t, null.value    == NaN,            fmt.tprint("value",    null.value))
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


@(test)
test_load_las_example_3_canadian_well_logging_society :: proc(t: ^tt.T) {
	las_file, parsed_ok := load_las(
		"assets/example_3_canadian_well_logging_society.las",
		allocator=context.temp_allocator,
	)
	defer delete_las_data(&las_file)
	tt.expect(t, parsed_ok == nil, fmt.tprint(parsed_ok))

	NaN := f64(-999.25)
	//  Version Section
	{   using las_file.version

		tt.expect(t, vers.mnemonic == "VERS",   fmt.tprint(vers.mnemonic))
		tt.expect(t, vers.unit     == "",       fmt.tprint(vers.unit))
		tt.expect(t, vers.value    == f64(2.0), fmt.tprint(vers.value))
		tt.expect(t, vers.descr    == "CWLS log ASCII Standard -VERSION 2.0", fmt.tprint(vers.descr))

		tt.expect(t, wrap.mnemonic == "WRAP", fmt.tprint(wrap.mnemonic))
		tt.expect(t, wrap.unit     == "",     fmt.tprint(wrap.unit))
		tt.expect(t, wrap.value    == true,   fmt.tprint(wrap.value))
		tt.expect(t, wrap.descr    == "Multiple lines per depth step", fmt.tprint(wrap.descr))

	}

	//  Well Information Section
	{   using las_file.well_info

		tt.expect(t, items[0].mnemonic == "STRT",        fmt.tprint(items[0].mnemonic))
		tt.expect(t, items[0].unit     == "M",           fmt.tprint(items[0].unit))
		tt.expect(t, items[0].value    == f64(910.00),   fmt.tprint(items[0].value))
		tt.expect(t, items[0].descr    == "START DEPTH", fmt.tprint(items[0].descr))

		tt.expect(t, items[1].mnemonic == "STOP",         fmt.tprint(items[1].mnemonic))
		tt.expect(t, items[1].unit     == "M",            fmt.tprint(items[1].unit))
		tt.expect(t, items[1].value    == f64(909.5000),  fmt.tprint(items[1].value))
		tt.expect(t, items[1].descr    == "STOP DEPTH",   fmt.tprint(items[1].descr))

		tt.expect(t, items[2].mnemonic == "STEP",         fmt.tprint("mnemonic", items[2].mnemonic))
		tt.expect(t, items[2].unit     == "M",            fmt.tprint("unit",     items[2].unit))
		tt.expect(t, items[2].value    == f64(-0.1250),   fmt.tprint("value",    items[2].value))
		tt.expect(t, items[2].descr    == "STEP",         fmt.tprint("descr",    items[2].descr))

		tt.expect(t, null.mnemonic == "NULL",         fmt.tprint("mnemonic", null.mnemonic))
		tt.expect(t, null.unit     == "",             fmt.tprint("unit",     null.unit))
		tt.expect(t, null.value    == NaN,            fmt.tprint("value",    null.value))
		tt.expect(t, null.descr    == "NULL VALUE",   fmt.tprint("descr",    null.descr))

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

	{   using las_file.log_data

		tt.expect(t, slice.equal( logs[0], []f64{  +910.0000,  +909.8750,  +909.7500,  +909.6250,  +909.5000, }), fmt.tprint(logs[0]))
		tt.expect(t, slice.equal( logs[1], []f64{        NaN,        NaN,        NaN,        NaN,        NaN, }), fmt.tprint(logs[1]))
		tt.expect(t, slice.equal( logs[2], []f64{ +2692.7075, +2712.6460, +2692.8137, +2644.3650, +2586.2822, }), fmt.tprint(logs[2]))
		tt.expect(t, slice.equal( logs[3], []f64{     0.3140,     0.2886,     0.2730,     0.2765,     0.2996, }), fmt.tprint(logs[3]))
		tt.expect(t, slice.equal( logs[4], []f64{    19.4086,    23.3987,    22.5909,    18.4831,    13.9187, }), fmt.tprint(logs[4]))

	}

	// tt.expect(t, slice.equal(np_tensor.shape, []uint{5, 5}))
}


// ===================== BROKEN LAS TESTS =======================


@(test)
test_load_las_example_1_canadian_well_logging_society_broken :: proc(t: ^tt.T) {
	las_file, parsed_ok := load_las(
		"assets/example_1_canadian_well_logging_society_broken.las",
		allocator=context.temp_allocator,
	)
	defer delete_las_data(&las_file)
	tt.expect(t, parsed_ok == nil, fmt.tprint(parsed_ok))


	NaN := f64(-999.25)
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

	{   using las_file.curve_info
		tt.expect(t, len == 0,   fmt.tprint(len))

	}

	// tt.expect(t, slice.equal(np_tensor.shape, []uint{5, 5}))
}

package lasload

import "core:fmt"
import "core:os"
import ls "shared:lasio"

main :: proc() {
	if !(  len(os.args) >= 2  ) {
		fmt.printf("Require one file input!")
		return
	}

	file_name: string = os.args[1]
	las_file, parsed_ok := ls.load_las(
		file_name,
		4016,
		allocator=context.allocator,
		temp_allocator=context.temp_allocator,
	)
	// defer ls.delete_las_data(las_file)

	if parsed_ok != nil {
		fmt.printfln("Failed to parse the data, err: %v", parsed_ok)
	}

	curve_info : ^ls.CurveInformation
	log_data   : ^ls.LogData
	idx : int

	// idx:=-1

	{ // version
		fmt.println("\tVersion:")
		fmt.printfln("\t\t%v", las_file.version.vers)
		fmt.printfln("\t\t%v", las_file.version.wrap)
		if len(las_file.version.add) > 0 {
			for add in las_file.version.add {
				fmt.printfln("\t\t%v", add)
			}
		}
	}

	{ // well informations
		fmt.println("\tWell Information records:")
		well_info := &las_file.well_info
		for idx = 0; idx < cast(int)well_info.len; idx += 1 {
			fmt.printfln("\t\t[%v]==> %v", idx, well_info.items[idx])
		}
		fmt.printfln("\t\t[NULL]==> %v", well_info.null)
	}

	{ // curve informations
		curve_info = &las_file.curve_info
		fmt.printfln("\tCurve records: %v", curve_info.len)
		for idx = 0; idx < cast(int)curve_info.len; idx += 1 {
			fmt.printfln("\t\t[%v]==> %v", idx, curve_info.curves[idx])
		}
	}

	{ // parameters informations
		fmt.printfln("\tParameter records: %v", las_file.parameter_info.len)
		for idx = 0; idx < cast(int)las_file.parameter_info.len; idx += 1 {
			fmt.printfln("\t\t[%v]==> %v", idx, las_file.parameter_info.params[idx])
		}
	}

	{ // other informations
		fmt.printfln("\tOther Informations: %v", las_file.other_info.len)
		for info in las_file.other_info.info {
			fmt.printfln("\t\t%v", info)
		}
	}

	{ // log data
		log_data = &las_file.log_data
		n_rows := log_data.nrows
		n_curves := log_data.ncurves
		fmt.printfln("\tLog Curves: %v", las_file.other_info.len)
		fmt.printfln("\t\tWRAP MODE: %v", log_data.wrap)
		fmt.printfln("\t\tNROWS:     %v", n_rows)
		fmt.printfln("\t\tNCOLS:     %v", n_curves)
		for idx = 0; idx < cast(int)n_curves; idx += 1 {
			fmt.printfln("\t\tLOG[%v] (5/%v first data points) \t==> %v",
					idx,
					n_rows,
					log_data.logs[idx][:2])
		}
	}

	fmt.println("====================================================================")
	fmt.printfln("")

}

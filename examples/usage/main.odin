package usage

import "core:fmt"
import ls "shared:lasiodin"

main :: proc()
{
    las_file, parsed_ok := ls.load_las(
        "./assets/example_1_canadian_well_logging_society.las",
        allocator=context.temp_allocator,
    )
    defer ls.delete_las_data(&las_file)
	if parsed_ok != nil { fmt.printfln("Failed to parse the data, err: %v", parsed_ok) }

    log_data := &las_file.log_data
    n_rows   := log_data.nrows
    n_curves := cast(int)log_data.ncurves
    fmt.printfln("File Name: %v", las_file.file_name)
    fmt.printfln("Log Curves: %v", las_file.other_info.len)
    fmt.printfln("\tWRAP MODE: %v", log_data.wrap)
    fmt.printfln("\tNROWS:     %v", n_rows)
    fmt.printfln("\tNCOLS:     %v", n_curves)
    for idx : int = 0; idx < n_curves; idx += 1 {
        fmt.printfln(
            "\tLOG[%v] %v \t==> %v",
            idx,
            n_rows,
            log_data.logs[idx]
        )
    }

    fmt.printfln("LasData:\n%#v", las_file)
}


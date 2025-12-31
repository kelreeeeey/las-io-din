# lasiodin

LAS file IO toolkit for petrophysical data written in Odin

# Features, or overview (I guess)

- [x] Parse LAS Format 2.0 with wrap flag = false
- [x] Parse LAS Format 2.0 with wrap flag = true
- [ ] Parse LAS Format 3.0 (I'll save it for the future)

- `lasiodin.load_las` returns
    1. one big struct, `LasData` (see [las_item.odin](./lasiodin/las_item.odin)), and
    2. a parse error, `ReadFileError` union, see [lasio.odin](./lasiodin/errors.odin)

- [`LasData`](./lasiodin/las_item.odin) contains all possible section defined by [LAS 2.0 specification](https://help.seequent.com/Workbench/en-GB/Content/Resources/DownloadableAssets/Las%202.0%20format%20description.pdf) which are 1) version information, 2) well information, 3) curve information, 4) parameter information, 5) other information, and 6) log data.

Underlying data structure that I used here are very straight forward as the LAS 2.0 specification. The primitive types of LAS in this matter are mnemonic, unit, value, and description which is underlying the basis structure for version information, well information, curve information, and parameter information. Mnemonic, unit, value, and description modeled through `HeaderItem` struct. Other information and log data in other hand have their own format, respectively, array of string (`[]string`) and map of int to array of float, (`map[int][]f64`).

Curve information struct shares the exact same keys as the log data map indicating that curve information also has a field, named `curves` which is map of int to `HeaderItem`s, hence, we can access both of each log data and their corresponding curve information using array indexing. This design api might change overtime, considering the current memory layout of log data is not as optimized and flexible as if it were flat array in which one can modify its strides and access pattern down to each log sample. Though, current implementation can be easily applied to LAS 3.0 where the log data can holds non numerical data sample, hence converting it to flat array would be quite tricky and tedious to handle.


# Usage

Other examples can be found in [examples/](./examples/)

```odin
package usage

import "core:fmt"
// here I already make a symlink in odin's shared directory to lasioodin/lasioodin
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
```

will print out following:
```raw
File Name: ./assets/example_1_canadian_well_logging_society.las
Log Curves: 2
        WRAP MODE: false
        NROWS:     3
        NCOLS:     8
        LOG[0] 3        ==> [1670, 1669.875, 1669.75]
        LOG[1] 3        ==> [123.45, 123.45, 123.45]
        LOG[2] 3        ==> [2550, 2550, 2550]
        LOG[3] 3        ==> [0.45, 0.45, 0.45]
        LOG[4] 3        ==> [123.45, 123.45, 123.45]
        LOG[5] 3        ==> [123.45, 123.45, 123.45]
        LOG[6] 3        ==> [110.2, 110.2, 110.2]
        LOG[7] 3        ==> [5.5999999999999996, 5.5999999999999996, 105.59999999999999]
```

<details><summary>Expand me to see more output</summary>
	
```raw
LasData{
        file_name = "./assets/example_1_canadian_well_logging_society.las",
        version = Version{
                vers = HeaderItem{
                        mnemonic = "VERS",
                        unit = "",
                        value = 2,
                        descr = "CWLS LOG ASCII STANDARD -VERSION 2.0",
                },
                wrap = HeaderItem{
                        mnemonic = "WRAP",
                        unit = "",
                        value = false,
                        descr = "ONE LINE PER DEPTH STEP",
                },
                add = [],
        },
        well_info = WellInformation{
                len = 12,
                items = map[
                        5 = HeaderItem{
                                mnemonic = "FLD",
                                unit = "",
                                value = "WILDCAT",
                                descr = "FIELD",
                        },
                        4 = HeaderItem{
                                mnemonic = "WELL",
                                unit = "",
                                value = "ANY ET AL 12-34-12-34",
                                descr = "WELL",
                        },
                        7 = HeaderItem{
                                mnemonic = "PROV",
                                unit = "",
                                value = "ALBERTA",
                                descr = "PROVINCE",
                        },
                        6 = HeaderItem{
                                mnemonic = "LOC",
                                unit = "",
                                value = "12-34-12-34W5M",
                                descr = "LOCATION",
                        },
                        1 = HeaderItem{
                                mnemonic = "STOP",
                                unit = "M",
                                value = 1669.75,
                                descr = "STOP DEPTH",
                        },
                        0 = HeaderItem{
                                mnemonic = "STRT",
                                unit = "M",
                                value = 1670,
                                descr = "START DEPTH",
                        },
                        3 = HeaderItem{
                                mnemonic = "COMP",
                                unit = "",
                                value = "ANY OIL COMPANY INC.",
                                descr = "COMPANY",
                        },
                        2 = HeaderItem{
                                mnemonic = "STEP",
                                unit = "M",
                                value = -0.125,
                                descr = "STEP",
                        },
                        9 = HeaderItem{
                                mnemonic = "DATE",
                                unit = "",
                                value = "13-DEC-86",
                                descr = "LOG DATE",
                        },
                        8 = HeaderItem{
                                mnemonic = "SRVC",
                                unit = "",
                                value = "ANY LOGGING COMPANY INC.",
                                descr = "SERVICE COMPANY",
                        },
                        11 = HeaderItem{
                                mnemonic = "LIC",
                                unit = "",
                                value = 23412,
                                descr = "ERCB LICENCE NUMB",
                        },
                        10 = HeaderItem{
                                mnemonic = "UWI",
                                unit = "",
                                value = "100123401234W500",
                                descr = "UNIQUE WELL ID",
                        },
                ],
                null = HeaderItem{
                        mnemonic = "NULL",
                        unit = "",
                        value = -999.25,
                        descr = "NULL VALUE",
                },
        },
        curve_info = CurveInformation{
                len = 8,
                curves = map[
                        3 = HeaderItem{
                                mnemonic = "NPHI",
                                unit = "V/V",
                                value = "42 890 00 00",
                                descr = "4 NEUTRON POROSITY",
                        },
                        2 = HeaderItem{
                                mnemonic = "RHOB",
                                unit = "K/M3",
                                value = "45 350 01 00",
                                descr = "3 BULK DENSITY",
                        },
                        1 = HeaderItem{
                                mnemonic = "DT",
                                unit = "US/M",
                                value = "60 520 32 00",
                                descr = "2 SONIC TRANSIT TIME",
                        },
                        0 = HeaderItem{
                                mnemonic = "DEPT",
                                unit = "M",
                                value = "",
                                descr = "1 DEPTH",
                        },
                        7 = HeaderItem{
                                mnemonic = "ILD",
                                unit = "OHMM",
                                value = "07 120 46 00",
                                descr = "8 DEEP RESISTIVITY",
                        },
                        6 = HeaderItem{
                                mnemonic = "ILM",
                                unit = "OHMM",
                                value = "07 120 44 00",
                                descr = "7 MEDIUM RESISTIVITY",
                        },
                        5 = HeaderItem{
                                mnemonic = "SFLA",
                                unit = "OHMM",
                                value = "07 222 01 00",
                                descr = "6 SHALLOW RESISTIVITY",
                        },
                        4 = HeaderItem{
                                mnemonic = "SFLU",
                                unit = "OHMM",
                                value = "07 220 04 00",
                                descr = "5 SHALLOW RESISTIVITY",
                        },
                ],
        },
        parameter_info = ParameterInformation{
                len = 7,
                params = [
                        HeaderItem{
                                mnemonic = "MUD",
                                unit = "",
                                value = "GEL CHEM",
                                descr = "MUD TYPE",
                        },
                        HeaderItem{
                                mnemonic = "BHT",
                                unit = "DEGC",
                                value = 35.5,
                                descr = "BOTTOM HOLE TEMPERATURE",
                        },
                        HeaderItem{
                                mnemonic = "CSGL",
                                unit = "M",
                                value = 124.59999999999999,
                                descr = "BASE OF CASING",
                        },
                        HeaderItem{
                                mnemonic = "MATR",
                                unit = "",
                                value = "SAND",
                                descr = "NEUTRON MATRIX",
                        },
                        HeaderItem{
                                mnemonic = "MDEN",
                                unit = "",
                                value = 2710,
                                descr = "LOGGING MATRIX DENSITY",
                        },
                        HeaderItem{
                                mnemonic = "RMF",
                                unit = "OHMM",
                                value = 0.216,
                                descr = "MUD FILTRATE RESISTIVITY",
                        },
                        HeaderItem{
                                mnemonic = "DFD",
                                unit = "K/M3",
                                value = 1525,
                                descr = "DRILL FLUID DENSITY",
                        },
                ],
        },
        other_info = OtherInformation{
                len = 2,
                info = [
                        " Note: The logging tools became stuck at 625 metres causing the",
                        "data between 625 metres and 615 metres to be invalid.",
                ],
        },
        log_data = LogData{
                wrap = false,
                nrows = 3,
                ncurves = 8,
                logs = map[
                        0 = [
                                1670,
                                1669.875,
                                1669.75,
                        ],
                        1 = [
                                123.45,
                                123.45,
                                123.45,
                        ],
                        2 = [
                                2550,
                                2550,
                                2550,
                        ],
                        3 = [
                                0.45,
                                0.45,
                                0.45,
                        ],
                        4 = [
                                123.45,
                                123.45,
                                123.45,
                        ],
                        5 = [
                                123.45,
                                123.45,
                                123.45,
                        ],
                        6 = [
                                110.2,
                                110.2,
                                110.2,
                        ],
                        7 = [
                                5.5999999999999996,
                                5.5999999999999996,
                                105.59999999999999,
                        ],
                ],
        },
}
```
</details>

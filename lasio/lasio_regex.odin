package lasio

// RE_WELL_INFORMATION: string      = "^\([^.]*\)\.\([^:].?*\) \([^:]*\):\([^:*]*\)"
// RE_PARAMETER_INFORMATION: string = "^\([^.]*\)\.\([^:].?*\) \([^:]*\):\([^:*]*\)"
// RE_CURVE_INFORMATION: string     = "^\([^.]*\)\.\([^:].*?*\) \([^:]*\):\([^:*]*\)"
//
// RE_MNEMONICS :: "^([^.]*)"
// RE_UNIT      :: "([^: ]*?*)"
// RE_VALUE     :: "([^:\s].*)"
// RE_DESCR     :: "([^:*]*)$"
// RE_PATTERN   :: RE_MNEMONICS + `.` + RE_UNIT + `[ |\t]` + RE_VALUE + `:` + RE_DESCR 
// // RE_FOR_ALL: string               = "^\([^.]*\)\.\([^: ]*?*\)[ |\t]\([^:\s].*\):\([^:*]*\)$"
//

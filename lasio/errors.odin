package lasio

import "core:os"
import "core:io"
import "core:bufio"
import "core:mem"

ReadFileError :: union {
	OpenError,
	ReaderCreationError,
	mem.Allocator_Error,
	ReaderReadByteError,
	ParseHeaderError,
}

OpenError :: struct {
	file_name: string,
	error: os.Errno,
}

ReaderCreationError :: struct {
	file_name: string,
	stream: io.Stream,
}

ReaderReadByteError :: struct {
	file_name: string,
	reader: bufio.Reader,
}

ParseHeaderError :: struct {
	file_name: string,
	line:      string,
	message:   string,
}


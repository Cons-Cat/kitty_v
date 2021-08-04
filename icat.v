module main

import kitty
import flag
import os

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Kitty PNG fp')
	fp.skip_executable()
	image_path := fp.string('path', 0, '', 'Relative path to a PNG.')
	fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}
	image_data := os.read_bytes(image_path) or { []byte{} }
	kitty.print_png_at_point(image_data)
}

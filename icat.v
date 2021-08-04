module main

import kitty
import flag
import os

const (
	ppm_width  = 4
	ppm_height = 4
	ppm_data   = [
		Pixel{
			color: [byte(0), 0, 0]!
		},
		Pixel{
			color: [byte(100), 0, 0]!
		},
		Pixel{
			color: [byte(0), 0, 0]!
		},
		Pixel{
			color: [byte(255), 0, 255]!
		},
		Pixel{
			color: [byte(0), 0, 0]!
		},
		Pixel{
			color: [byte(0), 255, 175]!
		},
		Pixel{
			color: [byte(0), 0, 0]!
		},
		Pixel{
			color: [byte(0), 0, 0]!
		},
		Pixel{
			color: [byte(0), 0, 0]!
		},
		Pixel{
			color: [byte(0), 0, 0]!
		},
		Pixel{
			color: [byte(0), 15, 175]!
		},
		Pixel{
			color: [byte(0), 0, 0]!
		},
		Pixel{
			color: [byte(255), 0, 255]!
		},
		Pixel{
			color: [byte(0), 0, 0]!
		},
		Pixel{
			color: [byte(0), 0, 0]!
		},
		Pixel{
			color: [byte(255), 255, 255]!
		},
	]
)

struct Pixel {
	color [3]byte
}

fn (p Pixel) to_string() string {
	mut str := ''
	str += rune(p.color[0]).str()
	str += rune(p.color[1]).str()
	str += rune(p.color[2]).str()
	return str
}

struct PPM {
	data []Pixel
}

fn (p PPM) to_string() string {
	mut str := ''
	for pixel in p.data {
		str += pixel.to_string()
	}
	return str
}

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

	image_data := os.read_file(image_path) or {''}
	// kitty.print_png_at_point(image_data)

	ppm := PPM{
		data: ppm_data
	}
	kitty.print_rgb_at_point(ppm.to_string(), ppm_width, ppm_height)
}

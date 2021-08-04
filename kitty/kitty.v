module kitty

import os
import encoding.base64

type Options = map[string]string

// Values of `f` key
pub enum ImageFormat {
	rgb = 24
	rgba = 32
	png = 100
}

// Values of `t` key
pub enum TransmissionMedium {
	file = 70 // `f`
	direct_data = 104 // `d`
	shared_memory_object = 115 // `s`
	temporary_file = 116 // `t`
}

// Values of `a` key
pub enum Display {
	transmit = 84 // `T`
	previous = 112 // `p`
	transmit_nodisplay = 116 // `t`
}

pub fn print_png_at_point(image_data string) {
	print_image(image_data, ',a=T,f=100')
}

pub fn print_rgb_at_point(image_data string, width u32, height u32) {
	print_image(image_data, ',a=T,f=24,s=$width.str(),v=$height.str()')
}

pub fn print_rgba_at_point(image_data string, width u32, height u32) {
	print_image(image_data, ',a=T,f=32,s=$width.str(),v=$height.str()')
}

// https://sw.kovidgoyal.net/kitty/graphics-protocol
pub fn print_image(image_data string, image_options_str string) {
	mut out := os.stdout()
	image_options := image_options_str.bytes()
	mut b64_data := base64.encode_str(image_data)
	// b64_data = image_data
	mut b64_pos := 0
	mut chunk_buffer := []byte{len: 0, cap: 4128, init: 0}

	// Print the first chunk with image_options.
	if b64_data.len >= 4096 {
		serialize_gr_command(b64_data[..4096], 1, image_options, mut chunk_buffer)
	} else {
		serialize_gr_command(b64_data, 0, image_options, mut chunk_buffer)
	}

	out.write(chunk_buffer) or { panic(err) }

	if b64_data.len >= 4096 {
		// Print remaining chunks without options.
		for {
			chunk_buffer.clear()
			b64_pos += 4096
			// 4096 is the maximum size of a well behaving chunk.
			b64_slice := if b64_pos + 4096 < b64_data.len {
				b64_data[b64_pos..b64_pos + 4096]
			} else {
				b64_data[b64_pos..]
			}
			// m == 0 iff the encoded data is the final chunk.
			if b64_slice.len == 4096 {
				payload := b64_slice[..4096]
				serialize_gr_command(payload, 1, []byte{}, mut chunk_buffer)
				out.write(chunk_buffer) or { panic(err) }
			} else {
				payload := b64_slice
				serialize_gr_command(payload, 0, []byte{}, mut chunk_buffer)
				out.write(chunk_buffer) or { panic(err) }
				break
			}
		}
	}
	os.flush()
}

fn options_map_to_string(options Options) []byte {
	mut out := []byte{}
	for key, value in options {
		out << ',$key=$value'.bytes()
	}
	return out
}

// Put an array of bytes in the form Kitty reads.
fn serialize_gr_command(payload string, m int, image_options []byte, mut buffer []byte) {
	buffer << '\033_Gm=$m'.bytes()
	// image_options always starts with a `,` byte.
	buffer << image_options
	buffer << ';$payload\033\\'.bytes()
}

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

// https://sw.kovidgoyal.net/kitty/graphics-protocol
pub fn print_image(image_data string, image_options Options) {
	mut out := os.stdout()
	empty_options := map[string]string{}
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
				serialize_gr_command(payload, 1, empty_options, mut chunk_buffer)
				out.write(chunk_buffer) or { panic(err) }
			} else {
				payload := b64_slice
				serialize_gr_command(payload, 0, empty_options, mut chunk_buffer)
				out.write(chunk_buffer) or { panic(err) }
				break
			}
		}
	}
	os.flush()
}

// Put an array of bytes in the form Kitty reads.
fn serialize_gr_command(payload string, m int, image_options Options, mut buffer []byte) {
	buffer << '\033_Gm=$m'.bytes()
	for key, value in image_options {
		buffer << ',$key=$value'.bytes()
	}
	buffer << ';$payload\033\\'.bytes()
}
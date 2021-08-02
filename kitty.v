// import term
import flag
import os
import encoding.base64

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
	image_data := os.read_file(image_path) or { panic('Could not open a PNG at $image_path') }
	options := map{
		'a': 'T'
		'f': int(KittyImageFormat.png).str()
	}
	print_image_kitty(image_data, options)
}

type KittyOptions = map[string]string

// Values of `f` key
enum KittyImageFormat {
	rgb = 24
	rgba = 32
	png = 100
}

// Values of `t` key
enum KittyTransmissionMedium {
	file = 70 // `f`
	direct_data = 104 // `d`
	shared_memory_object = 115 // `s`
	temporary_file = 116 // `t`
}

// https://sw.kovidgoyal.net/kitty/graphics-protocol
fn print_image_kitty(image_data string, image_options KittyOptions) {
	mut out := os.stdout()
	empty_options := map[string]string{}
	mut b64_data := base64.encode_str(image_data)
	mut b64_pos := 0
	mut chunk_buffer := []byte{len: 0, cap: 4128, init: 0}

	// Print the first chunk with image_options.
	serialize_gr_command(b64_data[..4096], 1, image_options, mut chunk_buffer)
	out.write(chunk_buffer) or { panic(err) }

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
	os.flush()
}

// Put an array of bytes in the form Kitty reads.
fn serialize_gr_command(payload string, m int, image_options KittyOptions, mut buffer []byte) {
	buffer << '\033_Gm=$m'.bytes()
	for key, value in image_options {
		buffer << ',$key=$value'.bytes()
	}
	buffer << ';$payload\033\\'.bytes()
}

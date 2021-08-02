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
	mut chunk_buffer := ChunkBuffer{}

	chunk_buffer.data = []byte{len: 0, cap: 4128, init: 0}

	// Print the first chunk with image_options.
	serialize_gr_command(b64_data[..4096], 1, image_options, mut chunk_buffer)
	out.write(chunk_buffer.data) or { panic(err) }

	// Print remaining chunks without options.
	for {
		chunk_buffer.data.clear()
		// 4096 is the maximum size of a well behaving chunk.
		b64_data = b64_data[4096..]
		chunk := if b64_data.len > 4096 { b64_data[..4096] } else { b64_data[..b64_data.len] }
		// m == 0 iff the encoded data is the final chunk.
		if b64_data.len > 4096 {
			serialize_gr_command(chunk, 1, empty_options, mut chunk_buffer)
			out.write(chunk_buffer.data) or { panic(err) }
		} else {
			serialize_gr_command(chunk, 0, empty_options, mut chunk_buffer)
			out.write(chunk_buffer.data) or { panic(err) }
			break
		}
	}
	os.flush()
}

// Put an array of bytes in the form Kitty reads.
fn serialize_gr_command(payload string, m int, image_options KittyOptions, mut buffer ChunkBuffer) {
	buffer.write('\033_G')
	serialized_options := 'm=$m' // m == 0 if this is the final chunk.
	buffer.write(serialized_options)
	for key, value in image_options {
		current_option := ',$key=$value'
		buffer.write(current_option)
	}
	str := ';$payload\033\\'
	buffer.write(str)
}

struct ChunkBuffer {
mut:
	data []byte
}

fn (mut buffer ChunkBuffer) write(source &string) {
	buffer.data << source.bytes()
}

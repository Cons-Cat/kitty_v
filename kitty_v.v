// import term
import flag
import os
import encoding.base64

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Kitty PNG fp')
	// viewer.limit_free_args(0, 0)
	fp.skip_executable()
	image_path := fp.string('path', 0, '', 'Relative path to a PNG.')
	fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}
	// image_data := os.read_bytes(image_path) or { panic('Could not open a PNG at $image_path') }
	image_data := os.read_file(image_path) or { panic('Could not open a PNG at $image_path') }
	options := map{
		'a': 'T'
		'f': int(KittyImageFormat.png).str()
	}
	// print_image_kitty(image_path, options)
	print_image_kitty(image_data, options)
}

type KittyOptions = map[string]string

type KittyImageData = []byte | string

// Value of `f` key
enum KittyImageFormat {
	rgb = 24
	rgba = 32
	png = 100
}

// Value of `t` key
enum KittyTransmissionMedium {
	file = 70 // `f`
	direct_data = 104 // `d`
	shared_memory_object = 115 // `s`
	temporary_file = 116 // `t`
}

// https://sw.kovidgoyal.net/kitty/graphics-protocol
fn print_image_kitty(image_data string, image_options KittyOptions) {
	empty_options := map[string]string{}
	mut b64_data := base64.encode_str(image_data)

	// Print the first chunk, with image_options.
	print(serialize_gr_command(b64_data[..4096], 1, image_options))

	// Print remaining chunks, without options.
	for {
		// 4096 is the maximum size of a well behaving chunk.
		b64_data = b64_data[4096..]
		chunk := if b64_data.len > 4096 { b64_data[..4096] } else { b64_data[..b64_data.len] }
		// m is 0 iff the encoded data is the final chunk.
		if b64_data.len > 4096 {
			print(serialize_gr_command(chunk, 1, empty_options))
		} else {
			print(serialize_gr_command(chunk, 0, empty_options))
			return
		}
	}
}

// Put an array of bytes in the form Kitty reads.
fn serialize_gr_command(payload string, m int, image_options KittyOptions) string {
	mut serialized_options := 'm=$m' // Chunk type
	for key, value in image_options {
		serialized_options += ',$key=$value'
	}
	return '\033_G' + '$serialized_options' + ';' + '$payload' + '\033\\'
}

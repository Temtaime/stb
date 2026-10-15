#ifdef _WIN32
	// FIXME: stb bug
	#define WIN32
#endif

#include <stb.h>
#include <stb_image.h>
#include <stb_image_resize2.h>
#include <stb_rect_pack.h>
#include <stb_dxt.h>

#define STBIW_ZLIB_COMPRESS compress_for_stb_image_write
unsigned char* compress_for_stb_image_write(unsigned char* data, int data_len, int* out_len, int quality);
#include <stb_image_write.h>

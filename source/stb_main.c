#define restrict unused // bug 23808

#include "../lib/stb.h"
#include "../lib/stb_image.h"
#include "../lib/stb_image_resize.h"
#include "../lib/stb_rect_pack.h"
#include "../lib/stb_dxt.h"

#define STBIW_ZLIB_COMPRESS compress_for_stb_image_write
unsigned char *compress_for_stb_image_write(unsigned char *data, int data_len, int *out_len, int quality);
#include "../lib/stb_image_write.h"

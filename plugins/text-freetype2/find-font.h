#pragma once

#include <ft2build.h>
#include FT_FREETYPE_H

extern void load_os_font_list(void);
extern void free_os_font_list(void);
extern const char *get_font_path(const char *family, const char *style);

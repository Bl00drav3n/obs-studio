#include <util/darray.h>
#include "find-font.h"
#include "text-freetype2.h"

#import <Foundation/Foundation.h>

struct font_path_info {
	char *family;
	char *style;
	char *path;
};

static inline void font_path_info_free(struct font_path_info *info)
{
	bfree(info->family);
	bfree(info->style);
	bfree(info->path);
}

static DARRAY(struct font_path_info) font_list;

static void add_path_fonts(NSFileManager *file_manager, NSString *path)
{
	NSArray *files = NULL;
	NSError *error = NULL;

	files = [file_manager contentsOfDirectoryAtPath:path error:&error];

	for (NSString *file in files) {
		NSMutableString *full_path = [[NSMutableString alloc] init];
		[full_path setString:path];
		[full_path appendString:@"/"];
		[full_path appendString:file];

		FT_Face face;
		if (FT_New_Face(ft2_lib, full_path.UTF8String, 0, &face) != 0)
			continue;

		struct font_path_info info;
		info.family = bstrdup(face->family_name);
		info.style  = bstrdup(face->style_name);
		info.path   = bstrdup(full_path.UTF8String);
		da_push_back(font_list, &info);

		FT_Done_Face(face);
	}
}

void load_os_font_list(void)
{
	@autoreleasepool {
		BOOL is_dir;
		NSArray *paths = NSSearchPathForDirectoriesInDomains(
				NSLibraryDirectory, NSAllDomainsMask, true);

		for (NSString *path in paths) {
			NSFileManager *file_manager =
				[NSFileManager defaultManager];
			NSString *font_path =
				[path stringByAppendingPathComponent:@"Fonts"];

			bool folder_exists = [file_manager
					fileExistsAtPath:font_path
					isDirectory:&is_dir];

			if (folder_exists && is_dir)
				add_path_fonts(file_manager, font_path);
		}
	}
}

void free_os_font_list(void)
{
	for (size_t i = 0; i < font_list.num; i++)
		font_path_info_free(font_list.array + i);
	da_free(font_list);
}

const char *get_font_path(const char *family, const char *style)
{
	for (size_t i = 0; i < font_list.num; i++) {
		struct font_path_info *info = font_list.array + i;

		if (strcmp(info->family, family) == 0 &&
		    strcmp(info->style,  style)  == 0)
			return info->path;
	}

	return NULL;
}

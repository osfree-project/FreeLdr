/*!
 * @file strcat.c
 * @brief Mini-libc: concatenate two strings into a destination buffer.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Concatenate @a src1 and @a src2 into @a dest.
 * @param[out] dest Destination buffer. Not NULL.
 * @param[in]  src1 First source string. Not NULL.
 * @param[in]  src2 Second source string. Not NULL.
 * @return @a dest.
 */
char *
grub_strcat (char *dest, const char *src1, const char *src2)
{
  int l;

  l = grub_strlen(src1);
  grub_strcpy(dest, src1);
  grub_strcpy(dest + l, src2);

  return dest;
}

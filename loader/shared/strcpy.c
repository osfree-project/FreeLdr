/*!
 * @file strcpy.c
 * @brief Mini-libc: string copy.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Copy a NUL-terminated string, including the terminator.
 * @param[out] dest Destination buffer. Not NULL.
 * @param[in]  src  Source string. Not NULL.
 * @return @a dest.
 */
char *
grub_strcpy (char *dest, const char *src)
{
  grub_memmove (dest, src, grub_strlen (src) + 1);
  return dest;
}

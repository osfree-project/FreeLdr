/*!
 * @file strncpy.c
 * @brief Mini-libc: bounded string copy.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Copy at most @a n bytes from @a src to @a dest and NUL-terminate.
 * @param[out] dest Destination buffer. Not NULL.
 * @param[in]  src  Source string. Not NULL.
 * @param[in]  n    Maximum number of bytes to copy.
 * @return @a dest.
 */
char *
grub_strncpy (char *dest, const char *src, int n)
{
  int i;

  for (i = 0; i < n; i++) {
    dest[i] = src[i];
    if (!src[i]) break;
  }
  dest[n] = '\0';

  return dest;
}

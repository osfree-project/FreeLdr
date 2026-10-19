/*!
 * @file tolower.c
 * @brief Mini-libc: ASCII lowercase conversion.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Convert an ASCII uppercase letter to lowercase.
 * @param[in] c Character to convert.
 * @return @a c if it is not in 'A'..'Z', otherwise its lowercase form.
 */
int
grub_tolower (int c)
{
  if (c >= 'A' && c <= 'Z')
    return (c + ('a' - 'A'));

  return c;
}

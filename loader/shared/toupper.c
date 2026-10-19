/*!
 * @file toupper.c
 * @brief Mini-libc: ASCII uppercase conversion.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Convert an ASCII lowercase letter to uppercase.
 * @param[in] c Character to convert.
 * @return @a c if it is not in 'a'..'z', otherwise its uppercase form.
 */
int
grub_toupper (int c)
{
  if (c >= 'a' && c <= 'z')
    return (c + ('A' - 'a'));

  return c;
}

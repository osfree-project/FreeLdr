/*!
 * @file convtoascii.c
 * @brief Mini-libc: integer-to-ASCII conversion.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Convert an integer to ASCII into @a buf.
 *
 * The format specifier @a c selects the base: 'x' or 'X' = 16,
 * otherwise 10. On non-STAGE1_5 builds a negative @a num with 'd' is
 * written with a leading '-'.
 *
 * @param[out] buf Destination buffer. Not NULL.
 * @param[in]  c   Format specifier.
 * @param[in]  ... The integer value to convert (passed as a 32-bit word).
 * @return Pointer to the byte just past the last emitted digit.
 */
char *
convert_to_ascii (char *buf, int c,...)
{
  unsigned long num = *((&c) + 1), mult = 10;
  char *ptr = buf;

#ifndef STAGE1_5
  if (c == 'x' || c == 'X')
    mult = 16;

  if ((num & 0x80000000uL) && c == 'd')
    {
      num = (~num) + 1;
      *(ptr++) = '-';
      buf++;
    }
#endif

  do
    {
      int dig = num % mult;
      *(ptr++) = ((dig > 9) ? dig + 'a' - 10 : '0' + dig);
    }
  while (num /= mult);

  /* reorder to correct direction!! */
  {
    char *ptr1 = ptr - 1;
    char *ptr2 = buf;
    while (ptr1 > ptr2)
      {
        int tmp = *ptr1;
        *ptr1 = *ptr2;
        *ptr2 = tmp;
        ptr1--;
        ptr2++;
      }
  }

  return ptr;
}

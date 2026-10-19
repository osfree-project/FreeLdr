/*!
 * @file ltoa.c
 * @brief Mini-libc: integer-to-string conversion.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Convert @a n to its string representation in base @a radix.
 *
 * Note: the current implementation writes into the destination via a
 * fixed-size ``sizeof(buf)`` memset on a pointer, which only clears
 * the pointer width's worth of bytes. Preserved as-is to match the
 * original source.
 *
 * @param[in]  n     Value to convert.
 * @param[out] buf   Destination buffer. Not NULL.
 * @param[in]  radix Numeric base (2..16).
 * @return @a buf.
 */
char *ltoa(int n, char *buf, int radix)
{
  int m, i, l;
  char c;

  memset(buf, 0, sizeof(buf));

  i = 0;
  do
  {
    m = n % radix;
    n = n / radix;

    if (m <= 10) c = '0' + m;
    else c = 'a' + m;

    l = i + 1;
    /* shift letters forth */
    while (--l) buf[l] = buf[l - 1];
    /* a new letter */
    buf[0] = c;
    i++;
  } while (n);

  return buf;
}
